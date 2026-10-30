# MbnInterop.ps1 — shared C# interop for the Windows Mobile Broadband (MBN) COM API
# Hand-written from the Windows SDK header mbnapi.h (MBN has no registered typelib).

$src = @'
using System;
using System.Runtime.InteropServices;

namespace MbnApi
{
    [Flags]
    public enum MBN_DATA_CLASS : uint
    {
        NONE = 0, GPRS = 0x1, EDGE = 0x2, UMTS = 0x4, HSDPA = 0x8,
        HSUPA = 0x10, LTE = 0x20, CUSTOM = 0x80000000
    }
    public enum MBN_REGISTER_MODE : uint { NONE = 0, AUTOMATIC = 1, MANUAL = 2 }
    public enum MBN_READY_STATE : uint { OFF = 0, INITIALIZED = 1, SIM_NOT_INSERTED = 2, BAD_SIM = 3, FAILURE = 4, NOT_ACTIVATED = 5, DEVICE_LOCKED = 6, DEVICE_BLOCKED = 7 }
    public enum MBN_REGISTER_STATE : uint { NONE = 0, DEREGISTERED = 1, SEARCHING = 2, HOME = 3, ROAMING = 4, PARTNER = 5, DENIED = 6 }
    public enum MBN_ACTIVATION_STATE : uint { NONE = 0, ACTIVATED = 1, ACTIVATING = 2, DEACTIVATED = 3, DEACTIVATING = 4 }
    public enum MBN_CONNECTION_MODE : uint { PROFILE = 0, TMP_PROFILE = 1 }

    [StructLayout(LayoutKind.Sequential)]
    public struct MBN_PROVIDER
    {
        [MarshalAs(UnmanagedType.BStr)] public string providerID;
        public uint providerState;
        [MarshalAs(UnmanagedType.BStr)] public string providerName;
        public uint dataClass;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MBN_INTERFACE_CAPS
    {
        public uint cellularClass;
        public uint voiceClass;
        public uint dataClass;
        [MarshalAs(UnmanagedType.BStr)] public string customDataClass;
        public uint gsmBandClass;
        public uint cdmaBandClass;
        [MarshalAs(UnmanagedType.BStr)] public string customBandClass;
        public uint smsCaps;
        public uint controlCaps;
        [MarshalAs(UnmanagedType.BStr)] public string deviceID;
        [MarshalAs(UnmanagedType.BStr)] public string manufacturer;
        [MarshalAs(UnmanagedType.BStr)] public string model;
        [MarshalAs(UnmanagedType.BStr)] public string firmwareInfo;
    }

    [ComImport, Guid("DCBBBAB6-201B-4BBB-AAEE-338E368AF6FA"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMbnInterfaceManager
    {
        [PreserveSig] int GetInterface([MarshalAs(UnmanagedType.LPWStr)] string interfaceID, out IMbnInterface mbnInterface);
        [PreserveSig] int GetInterfaces(out IntPtr safeArrayOfVariants);
    }

    [ComImport, Guid("DCBBBAB6-2001-4BBB-AAEE-338E368AF6FA"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMbnInterface
    {
        [PreserveSig] int get_InterfaceID([MarshalAs(UnmanagedType.BStr)] out string interfaceID);
        [PreserveSig] int GetInterfaceCapability(out MBN_INTERFACE_CAPS interfaceCaps);
        [PreserveSig] int GetSubscriberInformation(out IntPtr subscriberInformation);
        [PreserveSig] int GetReadyState(out MBN_READY_STATE readyState);
        [PreserveSig] int InEmergencyMode([MarshalAs(UnmanagedType.VariantBool)] out bool emergencyMode);
        [PreserveSig] int GetHomeProvider(out MBN_PROVIDER homeProvider);
        [PreserveSig] int GetPreferredProviders(out IntPtr preferredProviders);
        [PreserveSig] int SetPreferredProviders(IntPtr preferredProviders, out uint requestID);
        [PreserveSig] int GetVisibleProviders(out uint age, out IntPtr visibleProviders);
        [PreserveSig] int ScanNetwork(out uint requestID);
        [PreserveSig] int GetConnection(out IMbnConnection mbnConnection);
    }

    [ComImport, Guid("DCBBBAB6-2009-4BBB-AAEE-338E368AF6FA"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMbnRegistration
    {
        [PreserveSig] int GetRegisterState(out uint registerState);
        [PreserveSig] int GetRegisterMode(out MBN_REGISTER_MODE registerMode);
        [PreserveSig] int GetProviderID([MarshalAs(UnmanagedType.BStr)] out string providerID);
        [PreserveSig] int GetProviderName([MarshalAs(UnmanagedType.BStr)] out string providerName);
        [PreserveSig] int GetRoamingText([MarshalAs(UnmanagedType.BStr)] out string roamingText);
        [PreserveSig] int GetAvailableDataClasses(out uint availableDataClasses);
        [PreserveSig] int GetCurrentDataClass(out uint currentDataClass);
        [PreserveSig] int GetRegistrationNetworkError(out uint registrationNetworkError);
        [PreserveSig] int GetPacketAttachNetworkError(out uint packetAttachNetworkError);
        [PreserveSig] int SetRegisterMode(MBN_REGISTER_MODE registerMode, [MarshalAs(UnmanagedType.LPWStr)] string providerID, uint dataClass, out uint requestID);
    }

    [ComImport, Guid("DCBBBAB6-200D-4BBB-AAEE-338E368AF6FA"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IMbnConnection
    {
        [PreserveSig] int get_ConnectionID([MarshalAs(UnmanagedType.BStr)] out string connectionID);
        [PreserveSig] int get_InterfaceID([MarshalAs(UnmanagedType.BStr)] out string interfaceID);
        [PreserveSig] int Connect(MBN_CONNECTION_MODE connectionMode, [MarshalAs(UnmanagedType.LPWStr)] string strProfile, out uint requestID);
        [PreserveSig] int Disconnect(out uint requestID);
        [PreserveSig] int GetConnectionState(out MBN_ACTIVATION_STATE connectionState, [MarshalAs(UnmanagedType.BStr)] out string profileName);
        [PreserveSig] int GetVoiceCallState(out uint voiceCallState);
        [PreserveSig] int GetActivationNetworkError(out uint networkError);
    }

    public static class SafeArrayUtil
    {
        [DllImport("oleaut32.dll")]
        private static extern int SafeArrayDestroy(IntPtr psa);

        // x64 SAFEARRAY: cDims@0 fFeatures@2 cbElements@4 cLocks@8 pvData@16 rgsabound.cElements@24
        public static object[] ToObjectArray(IntPtr psa)
        {
            try
            {
                int cb = Marshal.ReadInt32(psa, 4);
                int cElements = Marshal.ReadInt32(psa, 24);
                IntPtr pvData = Marshal.ReadIntPtr(psa, 16);
                object[] items = new object[cElements];
                if (cb == 24) // SAFEARRAY of VARIANT
                {
                    for (int i = 0; i < cElements; i++)
                        items[i] = Marshal.GetObjectForNativeVariant(new IntPtr(pvData.ToInt64() + i * 24));
                }
                else if (cb == 8) // SAFEARRAY of IUnknown*/IDispatch*
                {
                    for (int i = 0; i < cElements; i++)
                    {
                        IntPtr p = Marshal.ReadIntPtr(pvData, i * 8);
                        if (p != IntPtr.Zero) items[i] = Marshal.GetObjectForIUnknown(p);
                    }
                }
                else throw new Exception("Unexpected SAFEARRAY element size: " + cb);
                return items;
            }
            finally { SafeArrayDestroy(psa); }
        }
    }

    public static class MbnSession
    {
        public static object[] Open()
        {
            Type t = Type.GetTypeFromCLSID(new Guid("BDFEE05B-4418-11DD-90ED-001C257CCFF1")); // MbnInterfaceManager
            object mgrObj = Activator.CreateInstance(t);
            IMbnInterfaceManager mgr = (IMbnInterfaceManager)mgrObj;
            IntPtr psa;
            int hr = mgr.GetInterfaces(out psa);
            if (hr < 0) Marshal.ThrowExceptionForHR(hr);
            object[] items = SafeArrayUtil.ToObjectArray(psa);
            if (items == null || items.Length == 0) throw new Exception("No Mobile Broadband interface found (is the modem on?)");
            IMbnInterface iface = (IMbnInterface)items[0];
            IMbnConnection conn;
            hr = iface.GetConnection(out conn);
            if (hr < 0) Marshal.ThrowExceptionForHR(hr);
            return new object[] { iface, (IMbnRegistration)items[0], conn };
        }

        // SIM-less mode: skips GetConnection (which fails with 0x80070490 when no SIM is inserted).
        public static object[] OpenNoConnection()
        {
            Type t = Type.GetTypeFromCLSID(new Guid("BDFEE05B-4418-11DD-90ED-001C257CCFF1"));
            object mgrObj = Activator.CreateInstance(t);
            IMbnInterfaceManager mgr = (IMbnInterfaceManager)mgrObj;
            IntPtr psa;
            int hr = mgr.GetInterfaces(out psa);
            if (hr < 0) Marshal.ThrowExceptionForHR(hr);
            object[] items = SafeArrayUtil.ToObjectArray(psa);
            if (items == null || items.Length == 0) throw new Exception("No Mobile Broadband interface found (is the modem on?)");
            return new object[] { (IMbnInterface)items[0], (IMbnRegistration)items[0] };
        }
    }

    public static class MbnTool
    {
        static IMbnInterface iface;
        static IMbnRegistration reg;
        static IMbnConnection conn;
        static volatile string pendingResult = null;
        static volatile Exception pendingError = null;

        public static string DataClassToString(uint dc)
        {
            if ((dc & 0x80000000) != 0 && (dc & 0x3F) == 0)
                return "CUSTOM (modem-specific — check the Windows network icon for the actual LTE / 3G label)";
            string s = "";
            if ((dc & 0x20) != 0) s += "LTE+";
            if ((dc & 0x10) != 0) s += "HSUPA+";
            if ((dc & 0x8) != 0) s += "HSDPA+";
            if ((dc & 0x4) != 0) s += "UMTS(3G)+";
            if ((dc & 0x2) != 0) s += "EDGE+";
            if ((dc & 0x1) != 0) s += "GPRS+";
            if (s.EndsWith("+")) s = s.Substring(0, s.Length - 1);
            if (s.Length == 0) return "0x" + dc.ToString("X");
            return s;
        }

        public static string Status()
        {
            Open();
            string ifaceID; int hr = iface.get_InterfaceID(out ifaceID);
            if (hr < 0) Marshal.ThrowExceptionForHR(hr);
            MBN_INTERFACE_CAPS caps;
            hr = iface.GetInterfaceCapability(out caps);
            if (hr < 0) Marshal.ThrowExceptionForHR(hr);
            MBN_READY_STATE ready; hr = iface.GetReadyState(out ready);
            if (hr < 0) Marshal.ThrowExceptionForHR(hr);
            uint regState; hr = reg.GetRegisterState(out regState);
            if (hr < 0) Marshal.ThrowExceptionForHR(hr);
            uint cur, avail;
            hr = reg.GetCurrentDataClass(out cur); if (hr < 0) Marshal.ThrowExceptionForHR(hr);
            hr = reg.GetAvailableDataClasses(out avail); if (hr < 0) Marshal.ThrowExceptionForHR(hr);
            string provName; hr = reg.GetProviderName(out provName);
            if (hr < 0) provName = "?";
            MBN_ACTIVATION_STATE act; string profile;
            hr = conn.GetConnectionState(out act, out profile); if (hr < 0) Marshal.ThrowExceptionForHR(hr);

            string[] regN = { "NONE", "DEREGISTERED", "SEARCHING", "HOME", "ROAMING", "PARTNER", "DENIED" };
            string[] actN = { "NONE", "ACTIVATED", "ACTIVATING", "DEACTIVATED", "DEACTIVATING" };
            string[] readyN = { "OFF", "INITIALIZED", "SIM_NOT_INSERTED", "BAD_SIM", "FAILURE", "NOT_ACTIVATED", "DEVICE_LOCKED", "DEVICE_BLOCKED" };

            return "Interface ID     : " + ifaceID + "\r\n"
                 + "Device           : " + caps.manufacturer + " " + caps.model + " (fw " + caps.firmwareInfo + ")\r\n"
                 + "Ready state      : " + readyN[(int)ready] + "\r\n"
                 + "Operator         : " + provName + "\r\n"
                 + "Register state   : " + regN[(int)regState] + "\r\n"
                 + "Connection       : " + actN[(int)act] + "  (profile: " + profile + ")\r\n"
                 + "Current tech     : " + DataClassToString(cur) + "\r\n"
                 + "Supported techs  : " + DataClassToString(avail);
        }

        private static void Open()
        {
            object[] o = MbnSession.Open();
            iface = (IMbnInterface)o[0];
            reg = (IMbnRegistration)o[1];
            conn = (IMbnConnection)o[2];
        }

        public static string Switch(bool prefer3g)
        {
            Open();
            uint THREE_G = 0x1F;   // GPRS|EDGE|UMTS|HSDPA|HSUPA (everything except LTE)
            uint LTE_ALL = 0x3F;   // everything (highest available wins => LTE when present)
            uint target = prefer3g ? THREE_G : LTE_ALL;
            string label = prefer3g ? "3G / HSPA+ (LTE disabled)" : "LTE/4G preferred";

            System.Collections.Generic.List<string> log = new System.Collections.Generic.List<string>();

            MBN_ACTIVATION_STATE act; string profile;
            int hr = conn.GetConnectionState(out act, out profile);
            if (hr < 0) Marshal.ThrowExceptionForHR(hr);

            if (act == MBN_ACTIVATION_STATE.ACTIVATED || act == MBN_ACTIVATION_STATE.ACTIVATING)
            {
                uint req; hr = conn.Disconnect(out req);
                if (hr < 0) Marshal.ThrowExceptionForHR(hr);
                log.Add("Disconnecting data connection...");
                for (int i = 0; i < 30; i++)
                {
                    System.Threading.Thread.Sleep(700);
                    MBN_ACTIVATION_STATE a; string p;
                    conn.GetConnectionState(out a, out p);
                    if (a >= MBN_ACTIVATION_STATE.DEACTIVATED) break;
                }
            }

            uint req2;
            hr = reg.SetRegisterMode(MBN_REGISTER_MODE.AUTOMATIC, null, target, out req2);
            if (hr < 0) return "SetRegisterMode failed: 0x" + hr.ToString("X8") + "  (was a data connection still active?)";
            log.Add("Preference set: " + label + ". Waiting for re-registration...");

            for (int i = 0; i < 20; i++)
            {
                System.Threading.Thread.Sleep(2000);
                uint c2; reg.GetCurrentDataClass(out c2);
                uint r2; reg.GetRegisterState(out r2);
                if (r2 == (uint)MBN_REGISTER_STATE.HOME || r2 == (uint)MBN_REGISTER_STATE.ROAMING || r2 == (uint)MBN_REGISTER_STATE.PARTNER)
                {
                    string[] regN = { "NONE", "DEREGISTERED", "SEARCHING", "HOME", "ROAMING", "PARTNER", "DENIED" };
                    // this modem keeps re-selecting for a while after SetRegisterMode; give it extra settle time
                    System.Threading.Thread.Sleep(10000);
                    uint c3; reg.GetCurrentDataClass(out c3);
                    log.Add("Registered as      : " + regN[(int)r2] + " on " + DataClassToString(c3));
                    log.Add("Note: on this modem, confirm the active technology via the Windows network icon (shows LTE / 3G / H+).");
                    break;
                }
            }

            // reconnect
            string prof = (profile != null && profile.Length > 0) ? profile : "05EDADE4-E01F-4E0C-ACB8-53910F367009";
            uint req3;
            int hr3 = conn.Connect(MBN_CONNECTION_MODE.PROFILE, prof, out req3);
            log.Add(hr3 >= 0 ? ("Reconnecting profile '" + prof + "'...") :
                               ("Auto-reconnect note: if it does not come back on its own, run: netsh mbn connect interface=\"Cellular\" name=\"" + prof + "\""));
            return string.Join(Environment.NewLine, log.ToArray());
        }

        // Runs Switch() on a background thread so a GUI stays responsive.
        public static void BeginSwitch(bool prefer3g)
        {
            pendingResult = null; pendingError = null;
            System.Threading.Thread t = new System.Threading.Thread(delegate()
            {
                try { pendingResult = Switch(prefer3g); }
                catch (Exception ex) { pendingError = ex; }
            });
            t.SetApartmentState(System.Threading.ApartmentState.MTA);
            t.IsBackground = true;
            t.Start();
        }

        public static string PollSwitchResult()
        {
            if (pendingError != null) return "ERROR: " + pendingError.Message;
            return pendingResult;
        }

        // Network scan. This modem refuses scans while packet-attached (0xC0040002),
        // so disconnect first, scan, then reconnect.
        public static string Scan()
        {
            object[] o = MbnSession.Open();
            IMbnInterface iface = (IMbnInterface)o[0];
            IMbnConnection conn = (IMbnConnection)o[2];
            MBN_READY_STATE ready; int hr = iface.GetReadyState(out ready);
            if (hr < 0) Marshal.ThrowExceptionForHR(hr);
            string[] readyN = { "OFF", "INITIALIZED", "SIM_NOT_INSERTED", "BAD_SIM", "FAILURE", "NOT_ACTIVATED", "DEVICE_LOCKED", "DEVICE_BLOCKED" };

            // disconnect if attached
            MBN_ACTIVATION_STATE act; string profile;
            hr = conn.GetConnectionState(out act, out profile);
            if (hr >= 0 && (act == MBN_ACTIVATION_STATE.ACTIVATED || act == MBN_ACTIVATION_STATE.ACTIVATING))
            {
                uint reqD; conn.Disconnect(out reqD);
                for (int i = 0; i < 20; i++)
                {
                    System.Threading.Thread.Sleep(700);
                    MBN_ACTIVATION_STATE a; string p;
                    conn.GetConnectionState(out a, out p);
                    if (a >= MBN_ACTIVATION_STATE.DEACTIVATED) break;
                }
            }

            uint req;
            hr = iface.ScanNetwork(out req);
            if (hr < 0) return "ScanNetwork failed: 0x" + hr.ToString("X8");

            string[] stateNames = { "NONE", "HOME", "FORBIDDEN", "PREFERRED", "VISIBLE", "REGISTERED", "PREF-MULTI" };
            string result = null;
            for (int i = 0; i < 30; i++)
            {
                System.Threading.Thread.Sleep(5000);
                uint age; IntPtr psa;
                hr = iface.GetVisibleProviders(out age, out psa);
                if (hr < 0 || age == 0) continue;
                try
                {
                    object[] provs = SafeArrayUtil.ToObjectArray(psa);
                    var sb = new System.Text.StringBuilder();
                    sb.AppendLine("Ready state: " + readyN[(int)ready]);
                    sb.AppendLine("Visible providers (" + provs.Length + "):");
                    foreach (object p in provs)
                    {
                        try
                        {
                            MBN_PROVIDER pv = (MBN_PROVIDER)p;
                            string states = "";
                            for (int b = 0; b < 7; b++) if ((pv.providerState & (1u << b)) != 0) states += stateNames[b] + "|";
                            sb.AppendLine("  ID=" + pv.providerID + "  name='" + pv.providerName + "'  classes=0x" + pv.dataClass.ToString("X") + "  state=" + states.TrimEnd('|'));
                        }
                        catch (Exception ex) { sb.AppendLine("  <provider decode failed: " + ex.Message + ">"); }
                    }
                    result = sb.ToString();
                    break;
                }
                catch { /* keep polling */ }
            }

            // reconnect
            string prof = (profile != null && profile.Length > 0) ? profile : "7AD7456C-04CA-4A1D-8EA0-2E622DAC9765";
            uint req3;
            int hr3 = conn.Connect(MBN_CONNECTION_MODE.PROFILE, prof, out req3);
            string tail = (hr3 >= 0) ? ("Reconnecting profile '" + prof + "'...") :
                ("Reconnect note: run netsh mbn connect interface=\"Cellular\" name=\"" + prof + "\"");

            return result ?? ("Scan timed out after 150s (no provider cache). " + tail);
        }
    }
}
'@

Add-Type -TypeDefinition $src -Language CSharp





