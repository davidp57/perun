﻿// This class gathers all helper functions
using System;
using System.Reflection;
using System.Text.RegularExpressions;

internal class PerunHelper
{
    // Add error infomation
    public static void LogError(ref string[] arrLogHistory, string strEntryToAdd, int intDirection = 0, int intMarker = 0, string strType = " ", bool bSkipGui = false)
    {
        AddLog(0, ref arrLogHistory, strEntryToAdd, intDirection, intMarker, strType, bSkipGui);
    }

    // Add warning information
    public static void LogWarning(ref string[] arrLogHistory, string strEntryToAdd, int intDirection = 0, int intMarker = 0, string strType = " ", bool bSkipGui = false)
    {
        AddLog(1, ref arrLogHistory, strEntryToAdd, intDirection, intMarker, strType, bSkipGui);
    }

    // Add info information
    public static void LogInfo(ref string[] arrLogHistory, string strEntryToAdd, int intDirection = 0, int intMarker = 0, string strType = " ", bool bSkipGui = false)
    {
        AddLog(2, ref arrLogHistory, strEntryToAdd, intDirection, intMarker, strType, bSkipGui);
    }

    // Add debug information
    public static void LogDebug(ref string[] arrLogHistory, string strEntryToAdd, int intDirection = 0, int intMarker = 0, string strType = " ", bool bSkipGui = false)
    {
        AddLog(3, ref arrLogHistory, strEntryToAdd, intDirection, intMarker, strType, bSkipGui);
    }

    // Add log
    private static void AddLog(int logLevel, ref string[] arrLogHistory, string strEntryToAdd, int intDirection = 0, int intMarker = 0, string strType = " ", bool bSkipGui = false)
    {
        // Declare values
        string LogDirection;
        string LogMarker;

        // Set direction marker
        switch (intDirection)
        {
            case 1:
                LogDirection = ">";
                break;
            case 2:
                LogDirection = "<";
                break;
            case 3:
                LogDirection = "^";
                break;
            default:
                LogDirection = "-";
                break;
        }

        // Insert information about which log type we are curently handling
        string LogType;
        switch (logLevel)
        {
            case 0:
                LogType = "E";
                break;
            case 1:
                LogType = "W";
                break;
            case 2:
                LogType = "I";
                break;
            default:
                LogType = "D";
                break;
        }

        // Set marker for user flags (markers)
        LogMarker = (intMarker > 0) ? "X" : " ";

        // Set frame type 
        strType = strType.PadLeft(3, ' ');

        if (!bSkipGui) // Shall we skip GUI?
        {
            // Rotate log history
            for (int i = 0; i < arrLogHistory.Length - 1; i++)
            {
                arrLogHistory[i] = arrLogHistory[i + 1]; // Shift one down
            }

            // Add new entry
            arrLogHistory[arrLogHistory.Length - 1] = DateTime.Now.ToString("HH:mm:ss.fff") + " " + LogDirection + " " + LogType + " " + strEntryToAdd; // Add entry at the last position

            // Update control at my window
            Globals.AppUpdateGUI = true;
        }
        // Add the entry to log file
        LogController.instance.WriteLog(logLevel, DateTime.Now.ToString("yyyy-MM-dd ") + " " + DateTime.Now.ToString("HH:mm:ss.fff") + " | Instance: " + Globals.AppInstanceID + " | " + LogMarker + " | " + LogDirection + " | " + strType + " | " + strEntryToAdd);
    }

    // Gets build version
    public static string GetAppVersion(string strBeginning)
    {
        Globals.VersionPerun = Assembly.GetExecutingAssembly().GetName().Version.ToString();
        return strBeginning + "v" + Globals.VersionPerun;
    }

    public static int CheckVersions()
    {
        // Checks if all versions (mysql, winapp, lua) are the same  - ommit if run as debug build
#if !DEBUG
        // Checks the versions of APP, DCS Hook and MySQL database
        Match match = Regex.Match(Globals.VersionPerun, @"^\d+.\d+.\d+", RegexOptions.Compiled | RegexOptions.IgnoreCase);
        string VersionApp = "v" + match.Groups[0].Value;

        int ReturnValue = 1;
        if (!String.IsNullOrEmpty(Globals.VersionDatabase))
        {
            // Check database
            if(VersionApp != Globals.VersionDatabase)
            {
                // Incorrect database version
                PerunHelper.LogError(ref Globals.AppLogHistory, "ERROR Incorrect database revision : "+ Globals.VersionDatabase, 1, 1, "?");
                Globals.ErrorsDatabase++;
                ReturnValue = 0;
            }
        }

        if (!String.IsNullOrEmpty(Globals.VersionDCSHook))
        {
            // Check database
            if (VersionApp != Globals.VersionDCSHook)
            {
                // Incorrect dcs script version
                PerunHelper.LogError(ref Globals.AppLogHistory, "ERROR Incorrect DCS hook revision : " + Globals.VersionDCSHook, 2, 1, "?");
                Globals.ErrorsGame++;
                ReturnValue = 0;
            }
        }

        return ReturnValue;
#else
        return 1;
#endif
    }

    public static string ConvertSecoundsToString (Double NumberOfSecounds){
        // TBD - convert number of secounds to HHhMMm format
        return NumberOfSecounds.ToString();
    }
}