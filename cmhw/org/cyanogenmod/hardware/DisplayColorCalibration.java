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

package org.cyanogenmod.hardware;

import java.io.File;
import org.cyanogenmod.hardware.util.FileUtils;

public class DisplayColorCalibration {
    private static final String COLOR_FILE = "/sys/devices/omapdss/display0/gamma_tuning";
    private static final String DEFAULT_COLORS = "255 255 255";

    public static boolean isSupported() {
        File file = new File(COLOR_FILE);
        return file.canRead() && file.canWrite()
                && normalizeColors(FileUtils.readOneLine(COLOR_FILE)) != null;
    }

    public static int getMaxValue() {
        return 255;
    }

    public static int getMinValue() {
        return 0;
    }

    public static int getDefValue() {
        return 255;
    }

    public static String getCurColors() {
        String colors = normalizeColors(FileUtils.readOneLine(COLOR_FILE));
        return colors != null ? colors : DEFAULT_COLORS;
    }

    public static boolean setColors(String colors) {
        String normalized = normalizeColors(colors);
        return normalized != null
                && FileUtils.writeLine(COLOR_FILE, normalized.replace(' ', ','));
    }

    private static String normalizeColors(String colors) {
        if (colors == null) {
            return null;
        }
        String[] values = colors.trim().replace(',', ' ').split("\\s+");
        if (values.length != 3) {
            return null;
        }
        int[] rgb = new int[3];
        try {
            for (int i = 0; i < rgb.length; i++) {
                rgb[i] = Integer.parseInt(values[i]);
                if (rgb[i] < getMinValue() || rgb[i] > getMaxValue()) {
                    return null;
                }
            }
        } catch (NumberFormatException e) {
            return null;
        }
        return rgb[0] + " " + rgb[1] + " " + rgb[2];
    }
}
