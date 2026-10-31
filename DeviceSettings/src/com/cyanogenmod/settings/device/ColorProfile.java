/*
 * Copyright (C) 2026 The CyanogenMod Project
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.cyanogenmod.settings.device;

import android.content.Context;
import android.preference.ListPreference;
import android.preference.Preference;
import android.preference.PreferenceManager;
import android.util.Log;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public final class ColorProfile implements Preference.OnPreferenceChangeListener {
    public static final String KEY = "gamma_profile";
    private static final String NODE = "/sys/devices/omapdss/display0/gamma_profile";

    private static boolean valid(String value) {
        return "0".equals(value) || "1".equals(value) || "2".equals(value);
    }

    private static String read() {
        try {
            BufferedReader reader = new BufferedReader(new FileReader(NODE));
            try {
                String value = reader.readLine();
                value = value == null ? null : value.trim();
                return valid(value) ? value : null;
            } finally {
                reader.close();
            }
        } catch (IOException e) {
            return null;
        }
    }

    private static boolean write(String value) {
        if (!valid(value)) return false;
        try {
            FileWriter writer = new FileWriter(NODE);
            try {
                writer.write(value);
            } finally {
                writer.close();
            }
            return value.equals(read());
        } catch (IOException e) {
            Log.e("LU5400ColorProfile", "Unable to apply color profile", e);
            return false;
        }
    }

    public static void restore(Context context) {
        if (read() == null) return;
        String value = PreferenceManager.getDefaultSharedPreferences(context)
                .getString(KEY, "0");
        write(valid(value) ? value : "0");
    }

    public static void configure(ListPreference preference) {
        String current = read();
        preference.setEnabled(current != null && new File(NODE).canWrite());
        if (current != null) {
            preference.setValue(current);
            preference.setSummary(preference.getEntry());
        }
        preference.setOnPreferenceChangeListener(new ColorProfile());
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        if (!(newValue instanceof String) || !write((String) newValue)) return false;
        ListPreference list = (ListPreference) preference;
        int index = list.findIndexOfValue((String) newValue);
        list.setSummary(list.getEntries()[index]);
        return true;
    }
}
