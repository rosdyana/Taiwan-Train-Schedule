/**
* Copyright (C) 2016 Rosdyana Kusuma <rosdyana.kusuma@gmail.com>
* 
* This program is free software; you can redistribute it and/or modify it under
* the terms of the GNU General Public License as published by the Free Software
* Foundation; either version 3 of the License, or (at your option) any later
* version.
* 
* This program is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
* details.
* 
* You should have received a copy of the GNU General Public License along with
* this program; if not, see <http://www.gnu.org/licenses/>.
**/
using CommandLine;
using CommandLine.Text;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;

namespace Taiwan_Train_Schedule
{
    //http://commandline.codeplex.com/documentation
    class Options
    {
        [Option('F', "from", Required = true,
            HelpText = "Input origin of train station.")]
        public string fromStation { get; set; }

        [Option('T', "to", Required = true,
            HelpText = "Input destination of train station.")]
        public string toStation { get; set; }

        [Option('s',"start time",
            HelpText = "Input start time.")]
        public string startTime { get; set; }

        [Option('e', "end time", DefaultValue = "2359",
            HelpText = "Input end time.")]
        public string endTime { get; set; }

        [Option('d',"date",
            HelpText = "Input date , format yyyy/mm/dd, by default is today.")]
        public string date { get; set; }

        [Option('c',"class", DefaultValue = "2",
            HelpText = "Input the car class  0 = express , 1 = ordinary , 2 = all types.")]
        public string carClass { get; set; }

        [ParserState]
        public IParserState LastParserState { get; set; }

        [HelpOption]
        public string GetUsage()
        {
            return HelpText.AutoBuild(this,
              (HelpText current) => HelpText.DefaultParsingErrorsHandler(this, current));
        }
    }
    class Program
    {
        static void Main(string[] args)
        {
            //list of train station in Taiwan with their unique id
            HashSet<string> StationList = new HashSet<string>(new string[]
            {
                "Fulong,1810","Gongliao,1809","Shuangxi,1808","Mudan,1807","Sandiaoling,1806","Houtong,1805","Ruifang,1804","Sijiaoting,1803","Nuannuan,1802","Keelung,1001",
                "Sangkeng,1029", "Badu,1002","Qidu,1003","Baifu,1030","Wudu,1004","Xizhi,1005","Xike,1031","Nangang,1006","Songshan,1007","Taipei,1008","Wanhua,1009",
                "Banqiao,1011","Fuzhao,1032","Shulin,1012","South Shulin,1034","Shanjia,1013","Yingge,1014",
                "Touyuan,1015","Neili,1016","Zhongli,1017","Puxin,1018","Yangmei,1019","Fugang,1020"
            });

            //https://msdn.microsoft.com/en-us/library/8kb3ddd4(v=vs.110).aspx
            TimeZone zone = TimeZone.CurrentTimeZone;
            DateTime local = zone.ToLocalTime(DateTime.Now);


            //delete previous html result
            string dir = AppDomain.CurrentDomain.BaseDirectory;
            DirectoryInfo di = new DirectoryInfo(dir);
            FileInfo[] files = di.GetFiles("*.html")
                                 .Where(p => p.Extension == ".html").ToArray();
            foreach (FileInfo file in files)
                try
                {
                    file.Attributes = FileAttributes.Normal;
                    File.Delete(file.FullName);
                }
                catch { }

            var options = new Options();
            if (CommandLine.Parser.Default.ParseArguments(args, options))
            {
                if (options.date == null) options.date = local.ToString("yyyy/MM/dd");
                if (options.startTime == null) options.startTime = local.ToString("HHmm");

                foreach (string x in StationList)
                {
                    var j = x.Split(',');
                    if (options.fromStation.IndexOf(j[0], StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        options.fromStation = j[1];
                    }
                    else if (options.toStation.IndexOf(j[0], StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        options.toStation = j[1];
                    }
                }
                
                string postData = "http://twtraffic.tra.gov.tw/twrail/SearchResult.aspx?searchtype=0&searchdate=" + options.date + "&fromstation=" + options.fromStation + "&tostation=" + options.toStation + "&trainclass=" + options.carClass + "&fromtime=" + options.startTime.Replace(":", "")+"&totime="+options.endTime+"&language=eng";

                WebRequest request = WebRequest.Create(postData);
                WebResponse response = request.GetResponse();

                // Get the stream containing content returned by the server.
                Stream dataStream = response.GetResponseStream();

                // Open the stream using a StreamReader for easy access.
                StreamReader reader = new StreamReader(dataStream);

                // Read the content.
                string responseFromServer = reader.ReadToEnd();

                // Clean up the streams and the response.
                reader.Close();
                response.Close();

                //save to html format and open it via web browser
                var fileName = Guid.NewGuid() + ".html";
                using (System.IO.StreamWriter file = new System.IO.StreamWriter(fileName, true))
                {
                    file.WriteLine(responseFromServer);
                }
                System.Diagnostics.Process.Start(fileName);
            }
            
        }
    }
}
