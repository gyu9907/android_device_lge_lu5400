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
import android.os.Parcel;

/** LU5400 uses the LG MDM6600 RIL, not the P940 XMM RIL.
 * Keep the product's class name while removing P940-only requests and events.
 * Native libril converts the stock ABI to the CM11 framework parcel format.
 */
public class P2RIL extends RIL implements CommandsInterface {
    public P2RIL(Context context, int networkMode, int cdmaSubscription) {
        super(context, networkMode, cdmaSubscription);
    }

    @Override
    protected void processUnsolicited(Parcel p) {
        int position = p.dataPosition();
        int response = p.readInt();
        p.setDataPosition(position);
        if (response >= 1050 && response <= 1094) {
            // LU540141: 1060 is HDR_SMPS_CHANGED, not P940 SIM_STATE_CHANGED.
            // Do not reinterpret unimplemented LG extensions as standard events.
            if (RILJ_LOGD) riljLog("LU5400 private unsolicited: " + response);
            return;
        }
        super.processUnsolicited(p);
    }
}
