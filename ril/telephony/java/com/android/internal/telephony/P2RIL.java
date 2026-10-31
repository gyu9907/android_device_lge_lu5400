/*
 * Copyright (C) 2013 The CyanogenMod Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.android.internal.telephony;

import android.content.Context;
import android.os.AsyncResult;
import android.os.Handler;
import android.os.Message;
import android.os.Parcel;

import com.android.internal.telephony.dataconnection.DataCallResponse;
import java.util.ArrayDeque;
import java.util.ArrayList;

/** LU5400 uses the LG MDM6600 RIL, not the P940 XMM RIL.
 * Keep the product's class name while removing P940-only requests and events.
 * Native libril converts the stock ABI to the CM12.1 framework parcel format.
 */
public class P2RIL extends RIL implements CommandsInterface {
    private static final int DATA_SETUP_DONE = 1;
    private static final int DATA_LIST_DONE = 2;
    private static final int DATA_DEACTIVATE_DONE = 3;
    private static final int DATA_VERIFY_DONE = 4;
    private final ArrayDeque<DataRequest> mDataRequests = new ArrayDeque<DataRequest>();
    private final Handler mDataHandler;
    // CM11 permits the single modem's normal setup/deactivate requests by default.
    private boolean mLegacyDataAllowed = true;

    private static class DataRequest {
        final Message result;
        final boolean allowed;
        final String[] setup;
        final ArrayDeque<Integer> activeCids = new ArrayDeque<Integer>();

        DataRequest(Message result, boolean allowed, String[] setup) {
            this.result = result;
            this.allowed = allowed;
            this.setup = setup;
        }
    }

    public P2RIL(Context context, int networkMode, int cdmaSubscription) {
        this(context, networkMode, cdmaSubscription, null);
    }

    public P2RIL(Context context, int networkMode, int cdmaSubscription, Integer instanceId) {
        super(context, networkMode, cdmaSubscription, instanceId);
        mDataHandler = new Handler(context.getMainLooper()) {
            @Override
            public void handleMessage(Message msg) {
                handleLegacyDataResponse(msg);
            }
        };
    }

    /**
     * LU540141 has no request 123 or separate packet-attach switch. Translate
     * the single-subscription permission into a local setup gate and the stock
     * DATA_CALL_LIST/DEACTIVATE_DATA_CALL operations. Completion acknowledges
     * this gate, never network registration or a successful packet attachment.
     * Do not send fake registration/data-attached notifications.
     */
    @Override
    public void setDataAllowed(boolean allowed, Message result) {
        enqueueDataRequest(new DataRequest(result, allowed, null));
    }

    @Override
    public void setupDataCall(String radioTechnology, String profile, String apn,
            String user, String password, String authType, String protocol, Message result) {
        enqueueDataRequest(new DataRequest(result, false, new String[] {
                radioTechnology, profile, apn, user, password, authType, protocol }));
    }

    // Serialize setup and permission changes through their modem callbacks:
    // disabling must also tear down a setup that was already in flight.
    private void enqueueDataRequest(final DataRequest request) {
        mDataHandler.post(new Runnable() {
            @Override
            public void run() {
                mDataRequests.add(request);
                if (mDataRequests.size() == 1) startDataRequest();
            }
        });
    }

    private void startDataRequest() {
        DataRequest request = mDataRequests.element();
        if (request.setup != null) {
            if (!mLegacyDataAllowed) {
                finishDataRequest(null, new CommandException(CommandException.Error.GENERIC_FAILURE));
                return;
            }
            String[] a = request.setup;
            super.setupDataCall(a[0], a[1], a[2], a[3], a[4], a[5], a[6],
                    mDataHandler.obtainMessage(DATA_SETUP_DONE));
        } else {
            mLegacyDataAllowed = request.allowed;
            if (RILJ_LOGD) riljLog("LU5400 legacy data gate: " + request.allowed);
            if (request.allowed) {
                finishDataRequest(null, null);
            } else {
                super.getDataCallList(mDataHandler.obtainMessage(DATA_LIST_DONE));
            }
        }
    }

    private void handleLegacyDataResponse(Message msg) {
        AsyncResult ar = (AsyncResult) msg.obj;
        if (ar.exception != null || msg.what == DATA_SETUP_DONE) {
            finishDataRequest(ar.result, ar.exception);
            return;
        }
        if (msg.what == DATA_DEACTIVATE_DONE) {
            deactivateNextDataCall();
            return;
        }
        if (!(ar.result instanceof ArrayList)) {
            finishDataRequest(null, new CommandException(CommandException.Error.GENERIC_FAILURE));
            return;
        }
        DataRequest request = mDataRequests.element();
        for (Object value : (ArrayList<?>) ar.result) {
            if (!(value instanceof DataCallResponse)) {
                finishDataRequest(null, new CommandException(CommandException.Error.GENERIC_FAILURE));
                return;
            }
            DataCallResponse call = (DataCallResponse) value;
            if (call.active != 0) {
                if (msg.what == DATA_VERIFY_DONE) {
                    finishDataRequest(null, new CommandException(CommandException.Error.GENERIC_FAILURE));
                    return;
                }
                request.activeCids.add(call.cid);
            }
        }
        if (msg.what == DATA_VERIFY_DONE || request.activeCids.isEmpty()) {
            finishDataRequest(null, null);
        } else {
            deactivateNextDataCall();
        }
    }

    private void deactivateNextDataCall() {
        DataRequest request = mDataRequests.element();
        if (request.activeCids.isEmpty()) {
            super.getDataCallList(mDataHandler.obtainMessage(DATA_VERIFY_DONE));
        } else {
            super.deactivateDataCall(request.activeCids.remove(), 0,
                    mDataHandler.obtainMessage(DATA_DEACTIVATE_DONE));
        }
    }

    private void finishDataRequest(Object value, Throwable error) {
        DataRequest request = mDataRequests.remove();
        if (request.result != null) {
            AsyncResult.forMessage(request.result, value, error);
            request.result.sendToTarget();
        }
        if (!mDataRequests.isEmpty()) startDataRequest();
    }

    @Override
    protected void processUnsolicited(Parcel p) {
        int position = p.dataPosition();
        int response = p.readInt();
        p.setDataPosition(position);
        if (response >= 1038 && response <= 1094) {
            // LU540141: 1060 is HDR_SMPS_CHANGED, not P940 SIM_STATE_CHANGED.
            // Do not reinterpret unimplemented LG extensions as standard events.
            if (RILJ_LOGD) riljLog("LU5400 private unsolicited: " + response);
            return;
        }
        super.processUnsolicited(p);
    }
}
