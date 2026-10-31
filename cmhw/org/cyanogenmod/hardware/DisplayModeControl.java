/*
 * Copyright (C) 2026 The CyanogenMod Project
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 */
package org.cyanogenmod.hardware;

import android.os.SystemProperties;
import android.util.Log;
import cyanogenmod.hardware.DisplayMode;
import java.io.File;
import java.util.Locale;
import org.cyanogenmod.hardware.util.FileUtils;

public final class DisplayModeControl {
    private static final String NODE = "/sys/devices/omapdss/display0/gamma_profile";
    private static final String PROPERTY = "persist.sys.lu5400.gamma";
    private static boolean sRestored;

    private static boolean valid(int id) {
        return id >= 0 && id <= 2;
    }

    private static int readMode() {
        String value = FileUtils.readOneLine(NODE);
        try {
            int id = Integer.parseInt(value == null ? "" : value.trim());
            return valid(id) ? id : -1;
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    private static DisplayMode mode(int id) {
        if (!valid(id)) return null;
        String[] names = "ko".equals(Locale.getDefault().getLanguage())
                ? new String[] { "LG 기본", "커스텀", "보정 없음" }
                : new String[] { "LG Default", "Custom", "Uncorrected" };
        return new DisplayMode(id, names[id]);
    }

    private static int savedMode() {
        int id = SystemProperties.getInt(PROPERTY, 0);
        return valid(id) ? id : 0;
    }

    private static boolean writeMode(int id) {
        return FileUtils.writeLine(NODE, Integer.toString(id)) && readMode() == id;
    }

    public static synchronized boolean isSupported() {
        File file = new File(NODE);
        if (!file.canRead() || !file.canWrite() || readMode() < 0) return false;
        if (!sRestored) {
            int saved = savedMode();
            if (readMode() != saved && !writeMode(saved)) return false;
            sRestored = true;
        }
        return true;
    }

    public static DisplayMode[] getAvailableModes() {
        return new DisplayMode[] { mode(0), mode(1), mode(2) };
    }

    public static synchronized DisplayMode getCurrentMode() {
        return mode(readMode());
    }

    public static DisplayMode getDefaultMode() {
        return mode(savedMode());
    }

    public static synchronized boolean setMode(DisplayMode requested, boolean makeDefault) {
        if (requested == null || !valid(requested.id)) return false;
        int previous = readMode();
        if (!valid(previous) || !writeMode(requested.id)) return false;
        if (makeDefault) {
            try {
                SystemProperties.set(PROPERTY, Integer.toString(requested.id));
            } catch (RuntimeException e) {
                writeMode(previous);
                Log.e("LU5400DisplayMode", "Unable to save color profile", e);
                return false;
            }
        }
        return true;
    }
}
