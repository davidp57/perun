﻿using Newtonsoft.Json;
using System;
using System.Diagnostics;
using System.Drawing;
using System.Threading;
using System.Windows.Forms;

namespace Perun_v1
{
    public partial class form_Main : Form
    {
        // Variable definitions
        public string[] arrMySQLSendBuffer = new string[65534];             // MySQL send buffer
        public bool bAllowAppClosure = false;                               // Helper to handle system tray

        public DatabaseController dcConnection = new DatabaseController();  // MySQL controller
        public TCPController tcpServer = new TCPController();                // TCP controller

        public bool bSRSStatus;                                             // Use empty/default SRS status
        public bool bLotATCStatus;                                          // Use empty/default LotATC status

        // ################################ Main ################################
        private void form_Main_Load(object sender, EventArgs e)
        {
            // Form loaded - fill controls with default values
            Globals.arrGUILogHistory[0] = DateTime.Now.ToString("HH:mm:ss") + " > " + "Perun started";

            // Display build version in title bar
            Globals.strPerunTitleText = PerunHelper.GetAppVersion(this.Text + " - ");
            this.Text = Globals.strPerunTitleText;

            // Load settings from registry
            form_Main_LoadSettings();

            // Use command line parameters
            string[] args = Environment.GetCommandLineArgs();
            if (args.Length > 1)
            {
                // Get argument server port
                if (args[1] != null)
                {
                    con_txt_dcs_server_port.Text = args[1];
                }
            }
            if (args.Length > 2)
            {
                // Get argument instance id
                if (args[2] != null)
                {
                    con_txt_dcs_instance.Text = args[2];
                }
            }
            if (args.Length > 3)
            {
                // Get argument DCS SRS file path
                if (args[3] != null)
                {
                    con_txt_3rd_srs.Text = args[3];
                    con_check_3rd_srs.Checked = true;
                }
            }
            if (args.Length > 4)
            {
                // Get argument lotATC file path
                if (args[4] != null)
                {
                    con_txt_3rd_lotatc.Text = args[4];
                    con_check_3rd_lotatc.Checked = true;
                }
            }

            // Initialize controls
            con_img_db.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected");
            con_img_dcs.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected");
            con_img_lotATC.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected");
            con_img_srs.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected");
        }

        public form_Main()
        {
            // Form init
            InitializeComponent();
        }

        // ################################ Helpers ################################
        private void form_Main_LoadSettings()
        {
            // Loads registry settings
            con_txt_mysql_database.Text = Properties.Settings.Default.MYSQL_DB;
            con_txt_mysql_username.Text = Properties.Settings.Default.MYSQL_User;
            con_txt_mysql_password.Text = Properties.Settings.Default.MYSQL_Password;
            con_txt_mysql_server.Text = Properties.Settings.Default.MYSQL_Server;
            con_txt_mysql_port.Text = Properties.Settings.Default.MYSQL_Port;
            con_txt_3rd_lotatc.Text = Properties.Settings.Default.OTHER_LOTATC_FILE;
            con_txt_3rd_srs.Text = Properties.Settings.Default.OTHER_SRS_FILE;
            con_check_3rd_lotatc.Checked = Properties.Settings.Default.OTHER_LOTATC_USE;
            con_check_3rd_srs.Checked = Properties.Settings.Default.OTHER_SRS_USE;
            con_txt_dcs_server_port.Text = Properties.Settings.Default.DCS_Server_Port.ToString();
            con_txt_dcs_instance.Text = Properties.Settings.Default.DCS_Instance.ToString();
        }

        private void form_Main_SaveSettings()
        {
            // Saves registry settings
            Properties.Settings.Default.MYSQL_Server = con_txt_mysql_database.Text;
            Properties.Settings.Default.MYSQL_DB = con_txt_mysql_database.Text;
            Properties.Settings.Default.MYSQL_User = con_txt_mysql_username.Text;
            Properties.Settings.Default.MYSQL_Password = con_txt_mysql_password.Text;
            Properties.Settings.Default.MYSQL_Port = con_txt_mysql_port.Text;
            Properties.Settings.Default.MYSQL_Server = con_txt_mysql_server.Text;
            Properties.Settings.Default.MYSQL_Port = con_txt_mysql_port.Text;
            Properties.Settings.Default.OTHER_LOTATC_FILE = con_txt_3rd_lotatc.Text;
            Properties.Settings.Default.OTHER_SRS_FILE = con_txt_3rd_srs.Text;
            Properties.Settings.Default.OTHER_LOTATC_USE = con_check_3rd_lotatc.Checked;
            Properties.Settings.Default.OTHER_SRS_USE = con_check_3rd_srs.Checked;
            Properties.Settings.Default.DCS_Server_Port = Int32.Parse(con_txt_dcs_server_port.Text);
            Properties.Settings.Default.DCS_Instance = Int32.Parse(con_txt_dcs_instance.Text);

            Properties.Settings.Default.Save();
        }

        private void form_Main_DisableControls()
        {
            // Disables controls
            con_Button_Listen_ON.Enabled = false;
            con_Button_Listen_OFF.Enabled = true;
            con_Button_Quit.Enabled = false;
            con_Button_Reset_Flags.Enabled = true;
            con_Button_Add_Marker.Enabled = true;
            con_txt_mysql_database.Enabled = false;
            con_txt_mysql_username.Enabled = false;
            con_txt_mysql_password.Enabled = false;
            con_txt_mysql_server.Enabled = false;
            con_txt_mysql_port.Enabled = false;
            con_txt_3rd_lotatc.Enabled = false;
            con_txt_3rd_srs.Enabled = false;
            con_check_3rd_lotatc.Enabled = false;
            con_check_3rd_srs.Enabled = false;
            con_txt_dcs_server_port.Enabled = false;
            con_txt_dcs_instance.Enabled = false;
        }

        private void form_Main_EnableControls()
        {
            // Enables controls
            con_Button_Listen_ON.Enabled = true;
            con_Button_Listen_OFF.Enabled = false;
            con_Button_Quit.Enabled = true;
            con_Button_Reset_Flags.Enabled = false;
            con_Button_Add_Marker.Enabled = false;
            con_txt_mysql_database.Enabled = true;
            con_txt_mysql_username.Enabled = true;
            con_txt_mysql_password.Enabled = true;
            con_txt_mysql_port.Enabled = true;
            con_txt_mysql_server.Enabled = true;
            con_txt_3rd_lotatc.Enabled = true;
            con_txt_3rd_srs.Enabled = true;
            con_check_3rd_lotatc.Enabled = true;
            con_check_3rd_srs.Enabled = true;
            con_txt_dcs_server_port.Enabled = true;
            con_txt_dcs_instance.Enabled = true;
            
        }

        // ################################ User input ################################
        private void con_Button_Listen_ON_Click(object sender, EventArgs e)
        {
            // Start listening
            // Set globals
            Globals.intInstanceId = Int32.Parse(con_txt_dcs_instance.Text);
            Globals.bStatusIconsForce = true;

            Globals.intMysqlErros = 0;                // Reset error counter
            Globals.intGameErros = 0;                 // Reset error counter
            Globals.intSRSErros = 0;                  // Reset error counter
            Globals.intLotATCErros = 0;               // Reset error counter

            Globals.bClientConnected = false;         // Reset connection status

            // Prepare GUI
            form_Main_DisableControls();
            form_Main_SaveSettings();
            this.Text = "[#" + con_txt_dcs_instance.Text + "] " + Globals.strPerunTitleText; // Set title bar
            trayIconMain.Text = this.Text; // Set notification icon text

            // Prepare MySQL connection string
            dcConnection.strMySQLConnectionString = "server=" + con_txt_mysql_server.Text + ";user=" + con_txt_mysql_username.Text + ";database=" + con_txt_mysql_database.Text + ";port=" + con_txt_mysql_port.Text + ";password=" + con_txt_mysql_password.Text;

            // Start listening
            PerunHelper.GUILogHistoryAdd(ref Globals.arrGUILogHistory, "#" + Globals.intInstanceId + " > " + "Opening connections");
            tcpServer.Create(Int32.Parse(con_txt_dcs_server_port.Text), ref Globals.arrGUILogHistory, ref arrMySQLSendBuffer);
            tcpServer.thrTCPListener = new Thread(tcpServer.StartListen);
            tcpServer.thrTCPListener.Start();
            tcpServer.thrTCPListener.Name = "TCPThread";

            // Start timmers
            tim_MySQL.Enabled = true;
            tim_GUI.Enabled = true;
            tim_3rdparties.Enabled = true;

            // Send initial data
            Tim_MySQL_Tick(null, null);
            tim_3rdparties_Tick(null, null);
        }

        private void con_Button_Listen_OFF_Click(object sender, EventArgs e)
        {
            // Stop listening
            // Prepare GUI
            PerunHelper.GUILogHistoryAdd(ref Globals.arrGUILogHistory, "#" + Globals.intInstanceId + " > " + "Closing connections");
            con_Button_Listen_OFF.Enabled = false;
            Tim_GUI_Tick(null, null);
            this.Refresh();
            Application.DoEvents();

            // Stop timmers
            tim_GUI.Enabled = false;
            tim_3rdparties.Enabled = false;
            tim_MySQL.Enabled = false;

            // Wait untill TCP server closed connection
            try
            {
                tcpServer.StopListen();
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }

            while (tcpServer.thrTCPListener.IsAlive)
            {
                Thread.Sleep(100); //ms
            }
            form_Main_EnableControls(); // Enable controls

            con_img_db.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected");
            con_img_dcs.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected");
            con_img_lotATC.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected");
            con_img_srs.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected");

            // Display information about closed connections
            PerunHelper.GUILogHistoryAdd(ref Globals.arrGUILogHistory, "#" + Globals.intInstanceId + " > " + "Connections closed");
            Tim_GUI_Tick(null, null);

            // Set title bar
            this.Text = Globals.strPerunTitleText;
            trayIconMain.Text = this.Text;

            // Set globals
            Globals.intInstanceId = 0;

            // Set helpers for updates
            Globals.bGUILogHistoryUpdate = false;
            Globals.bdcConnection = false;
            Globals.bTCPServer = false;
            Globals.bSRSStatus = false;
            Globals.bLotATCStatus = false;
            Globals.bClientConnected = false;
        }

        private void con_lab_github_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
        {
            // Open default browser with link to Perun repo
            ProcessStartInfo sInfo = new ProcessStartInfo("https://github.com/szporwolik/perun");
            Process.Start(sInfo);
        }

        private void con_txt_3rd_srs_Click(object sender, MouseEventArgs e)
        {
            // Chose SRS Json file
            if (openFileDialog_SRS.ShowDialog() == DialogResult.OK)
            {
                con_txt_3rd_srs.Text = openFileDialog_SRS.FileName;
                con_check_3rd_srs.Checked = true;
            }
            else
            {
                con_txt_3rd_srs.Text = "";
                con_check_3rd_srs.Checked = false;
            }
        }

        private void con_txt_3rd_lotatc_Click(object sender, MouseEventArgs e)
        {
            // Chose LotATC Json file
            if (openFileDialog_LotATC.ShowDialog() == DialogResult.OK)
            {
                con_txt_3rd_lotatc.Text = openFileDialog_LotATC.FileName;
                con_check_3rd_lotatc.Checked = true;
            }
            else
            {
                con_txt_3rd_lotatc.Text = "";
                con_check_3rd_lotatc.Checked = false;
            }
        }

        // ################################ Form state ################################
        private void con_Button_Quit_Click(object sender, EventArgs e)
        {
            // Close app
            DialogResult dialogResult = MessageBox.Show("Are you sure to exit Perun?", "Question", MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Question);
            if (dialogResult == DialogResult.Yes)
            {
                form_Main_SaveSettings();

                bAllowAppClosure = true; // Save settings on exit
                this.Close();        // Allow to exit application
            }
            else if (dialogResult == DialogResult.No)
            {
                //do nothing
            }
        }

        private void form_Main_SendToTray()
        {
            // Sends app to system tray
            trayIconMain.Visible = true;
            this.WindowState = FormWindowState.Minimized;
            this.ShowInTaskbar = false;
        }

        private void form_Main_BringFromTray()
        {
            // Sends app from system tray
            trayIconMain.Visible = false;
            this.WindowState = FormWindowState.Normal;
            this.ShowInTaskbar = true;

            if (WindowState == FormWindowState.Minimized)
            {
                WindowState = FormWindowState.Normal;
            }
            // get our current "TopMost" value (ours will always be false though)
            bool top = TopMost;
            // make our form jump to the top of everything
            TopMost = true;
            // set it back to whatever it was
            TopMost = top;
        }


        private void form_Main_FormClosing(object sender, FormClosingEventArgs e)
        {
            // Minimize to try on clicking "X"
            if (e.CloseReason == CloseReason.UserClosing && !bAllowAppClosure)
            {
                e.Cancel = true;
                form_Main_SendToTray(); // Send app to system tray
            }
        }

        private void trayIconMain_MouseDoubleClick(object sender, MouseEventArgs e)
        {
            // Maximize from tray
            form_Main_BringFromTray(); // Bring app from system tray
        }

        // ################################ Timers ################################
        private void Tim_GUI_Tick(object sender, EventArgs e)
        {
            // Main timer to sync GUI with background tasks and flush buffers

            // Refresh Log Window
            if (Globals.bGUILogHistoryUpdate)
            {
                con_List_Received.Items.Clear();
                foreach (string i in Globals.arrGUILogHistory)
                {
                    if (i != null)
                    {
                        con_List_Received.Items.Add(i);
                    }
                }
                Globals.bGUILogHistoryUpdate = false;
            }
            else
            {
                // Do nothing , control does not require update
            }

            // Update status icons at main form
            if ((dcConnection.bStatus != Globals.bdcConnection) || Globals.bStatusIconsForce)
            {
                if (dcConnection.bStatus)
                {
                    if (Globals.intMysqlErros == 0)
                    {
                        con_img_db.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_connected");
                    }
                    else
                    {
                        con_img_db.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_connected_error");
                    }
                }
                else
                {
                    con_img_db.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected_error");
                }
                Globals.bdcConnection = dcConnection.bStatus;
            }

            if ((Globals.bClientConnected != Globals.bTCPServer) || Globals.bStatusIconsForce || Globals.intGameErros != Globals.intGameErrosHistory)
            {
                if (Globals.bClientConnected)
                {
                    if (Globals.intGameErros == 0)
                    {
                        con_img_dcs.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_connected");
                    }
                    else
                    {
                        con_img_dcs.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_connected_error");
                    }
                }
                else
                {
                    con_img_dcs.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected_error");
                }
                Globals.bTCPServer = Globals.bClientConnected;
                Globals.intGameErrosHistory = Globals.intGameErros;
            }
            if ((bSRSStatus != Globals.bSRSStatus) || Globals.bStatusIconsForce)
            {
                if (bSRSStatus && con_check_3rd_srs.Checked)
                {
                    if (Globals.intSRSErros == 0)
                    {
                        con_img_srs.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_connected");
                    }
                    else
                    {
                        con_img_srs.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_connected_error");
                    }
                }
                else
                {
                    con_img_srs.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected_error");
                }
                Globals.bSRSStatus = bSRSStatus;
            }
            if ((bLotATCStatus != Globals.bLotATCStatus) || Globals.bStatusIconsForce)
            {
                if (bLotATCStatus && con_check_3rd_lotatc.Checked)
                {
                    if (Globals.intLotATCErros == 0)
                    {
                        con_img_lotATC.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_connected");
                    }
                    else
                    {
                        con_img_lotATC.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_connected_error");
                    }
                }
                else
                {
                    con_img_lotATC.Image = (Image)Properties.Resources.ResourceManager.GetObject("status_disconnected_error");
                }
                Globals.bLotATCStatus = bLotATCStatus;
            }
            Globals.bStatusIconsForce = false;
        }

        private void Tim_MySQL_Tick(object sender, EventArgs e)
        {
            // Send buffer to MySQL
            for (int i = 0; i < arrMySQLSendBuffer.Length - 1; i++)
            {
                if (arrMySQLSendBuffer[i] != null)
                {
                    dcConnection.SendToMySql(arrMySQLSendBuffer[i]);
                    arrMySQLSendBuffer[i] = null;
                }
            }
        }

        private void tim_3rdparties_Tick(object sender, EventArgs e)
        {
            // Main timer to send JSON files to MySQL
            string strSRSJson = "";
            string strLotATCJson = "";

            bool boolSRSdefault = true;
            bool boolLotATCdefault = true;

            // Handle SRS 
            if (con_check_3rd_srs.Checked)
            {
                try
                {
                    strSRSJson = System.IO.File.ReadAllText(con_txt_3rd_srs.Text);
                    dynamic raw_lotatc = JsonConvert.DeserializeObject(strSRSJson);

                    for (int i = 0; i < raw_lotatc.Count; i++)
                    {

                        if (raw_lotatc[i].RadioInfo != null)
                        {

                            int temp = raw_lotatc[i].RadioInfo.radios.Count - 1;
                            for (int j = temp; j >= 0; j--)
                            {
                                raw_lotatc[i].RadioInfo.radios[j].enc.Parent.Remove();
                                raw_lotatc[i].RadioInfo.radios[j].encKey.Parent.Remove();
                                raw_lotatc[i].RadioInfo.radios[j].encMode.Parent.Remove();
                                raw_lotatc[i].RadioInfo.radios[j].freqMax.Parent.Remove();
                                raw_lotatc[i].RadioInfo.radios[j].freqMin.Parent.Remove();
                                raw_lotatc[i].RadioInfo.radios[j].modulation.Parent.Remove();
                                raw_lotatc[i].RadioInfo.radios[j].freqMode.Parent.Remove();
                                raw_lotatc[i].RadioInfo.radios[j].volMode.Parent.Remove();
                                raw_lotatc[i].RadioInfo.radios[j].expansion.Parent.Remove();
                                raw_lotatc[i].RadioInfo.radios[j].channel.Parent.Remove();
                                raw_lotatc[i].RadioInfo.radios[j].simul.Parent.Remove();

                                if (raw_lotatc[i].RadioInfo.radios[j].name == "No Radio")
                                {
                                    raw_lotatc[i].RadioInfo.radios[j].Remove();
                                }
                            }
                            raw_lotatc[i].ClientChannelId.Parent.Remove();
                            raw_lotatc[i].RadioInfo.simultaneousTransmission.Parent.Remove();
                        }
                    }

                    if (raw_lotatc.Count > 0)
                    {
                        strSRSJson = JsonConvert.SerializeObject(raw_lotatc);
                        strSRSJson = "{'type':'100','instance':'" + Int32.Parse(con_txt_dcs_instance.Text) + "','payload':'" + strSRSJson + "'}";
                    }
                    else
                    {
                        strSRSJson = "{'type':'100','instance':'" + Int32.Parse(con_txt_dcs_instance.Text) + "','payload':{'ignore':'false'}}"; // No SRS clients connected
                    }
                    boolSRSdefault = false;
                    PerunHelper.GUILogHistoryAdd(ref Globals.arrGUILogHistory, "#" + Int32.Parse(con_txt_dcs_instance.Text) + " > SRS data loaded");
                    bSRSStatus = true;
                }
                catch (Exception exc_srs)
                {
                    PerunHelper.GUILogHistoryAdd(ref Globals.arrGUILogHistory, "#" + Int32.Parse(con_txt_dcs_instance.Text) + " > SRS data ERROR > " + exc_srs.Message);
                    bSRSStatus = false;
                    Globals.intSRSErros++;
                }


            }
            if (boolSRSdefault)
            {
                strSRSJson = "{'type':'100','instance':'" + Int32.Parse(con_txt_dcs_instance.Text) + "','payload':{'ignore':'true'}}";
            }
            dcConnection.SendToMySql(strSRSJson);

            // Handle LotATC 
            if (con_check_3rd_lotatc.Checked)
            {
                try
                {
                    strLotATCJson = System.IO.File.ReadAllText(con_txt_3rd_lotatc.Text);
                    dynamic raw_srs = JsonConvert.DeserializeObject(strLotATCJson);

                    strLotATCJson = "{'type':'101','instance':'" + Int32.Parse(con_txt_dcs_instance.Text) + "','payload':'" + strLotATCJson + "'}";
                    boolLotATCdefault = false;
                    PerunHelper.GUILogHistoryAdd(ref Globals.arrGUILogHistory, "#" + Int32.Parse(con_txt_dcs_instance.Text) + " > LotATC data loaded");
                    bLotATCStatus = true;
                }
                catch (Exception exc_lotatc)
                {
                    PerunHelper.GUILogHistoryAdd(ref Globals.arrGUILogHistory, "#" + Int32.Parse(con_txt_dcs_instance.Text) + " > LotATC data ERROR > " + exc_lotatc.Message);
                    bLotATCStatus = false;
                    Globals.intLotATCErros++;
                }


            }
            if (boolLotATCdefault)
            {
                strLotATCJson = "{'type':'101','instance':'" + Int32.Parse(con_txt_dcs_instance.Text) + "','payload':{'ignore':'true'}}";   // No LotATC controller connected
            }
            dcConnection.SendToMySql(strLotATCJson);

            // Let's do not risk int overload
            Globals.intMysqlErros = (Globals.intMysqlErros > 999) ? 999 : Globals.intMysqlErros;
            Globals.intGameErros = (Globals.intGameErros > 999) ? 999 : Globals.intGameErros;
            Globals.intSRSErros = (Globals.intSRSErros > 999) ? 999 : Globals.intSRSErros;
            Globals.intLotATCErros = (Globals.intLotATCErros > 999) ? 999 : Globals.intLotATCErros;

        }


        private void con_List_Received_SelectedIndexChanged(object sender, EventArgs e)
        {

        }

        private void con_Button_Reset_Flags_Click(object sender, EventArgs e)
        {
            // Reset error flags
            DialogResult dialogResult = MessageBox.Show("Are you sure to reset error flags?", "Question", MessageBoxButtons.YesNo, System.Windows.Forms.MessageBoxIcon.Question);
            if (dialogResult == DialogResult.Yes)
            {
                // Reset errors counter
                Globals.intMysqlErros = 0;                            // MySQL - Error counter
                Globals.intGameErros = 0;                             // TCP connection - Error counter
                Globals.intGameErrosHistory = 0;                      // TCP connection - historic value of Error counter
                Globals.intSRSErros = 0;                              // DCS SRS - error counter
                Globals.intLotATCErros = 0;                           // LotATC - error counter

                // Force icons reload
                Globals.bStatusIconsForce = true;

                // Add information
                PerunHelper.GUILogHistoryAdd(ref Globals.arrGUILogHistory, "#" + Globals.intInstanceId + " > " + "Resetted error counter");
            }
            else if (dialogResult == DialogResult.No)
            {
                // Do nothing
            }


    }

        private void con_Button_Add_Marker_Click(object sender, EventArgs e)
        {
            // Added user marker
            PerunHelper.GUILogHistoryAdd(ref Globals.arrGUILogHistory, "#" + Globals.intInstanceId + " > " + "User marker");
        }
    }
}
