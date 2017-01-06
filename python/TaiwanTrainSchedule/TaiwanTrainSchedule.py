import webbrowser
import platform
import os
from datetime import datetime
#import argparse

#parser = argparse.ArgumentParser()
#parser.add_argument('-F', help='', required=True)
#parser.add_argument('-T', help='', required=True)
#parser.add_argument('-s', help='', default='00:00')
#parser.add_argument('-e', help='', default='23:59')
#parser.add_argument('-d', help='')
#parser.add_argument('-c', help='', default='2')
#args = parser.parse_args()

if platform.system() == "Windows":
    os.system('cls')
else:
    os.system('clear')

print("\n")
print("     ########    ########        ###    ")
print("        ##       ##     ##      ## ##   ")
print("        ##       ##     ##     ##   ##  ")
print("        ##       ########     ##     ## ")
print("        ##       ##   ##      ######### ")
print("        ##       ##    ##     ##     ## ")
print("        ##       ##     ##    ##     ## ")
print("         Taiwan Railways Administration ")
print(" Copyright 2017 rosdyana.kusuma [at] gmail [dot] com ")

fromStation = str(raw_input('Departure Station : '))
toStation = str(raw_input('Arrival Station : '))
StationList = {'Taipei':1008, 'Neili':1016,"Fulong":1810,"Gongliao":1809,"Shuangxi":1808,"Mudan":1807,"Sandiaoling":1806,
               "Houtong":1805,"Ruifang":1804,"Sijiaoting":1803,"Nuannuan":1802,"Keelung":1001,"Sangkeng":1029, "Badu":1002,
               "Qidu":1003,"Baifu":1030,"Wudu":1004,"Xizhi":1005,"Xike":1031,"Nangang":1006,"Songshan":1007,"Taipei":1008,
               "Wanhua":1009,"Banqiao":1011,"Fuzhao":1032,"Shulin":1012,"South Shulin":1034,"Shanjia":1013,"Yingge":1014,
               "Touyuan":1015,"Neili":1016,"Zhongli":1017,"Puxin":1018,"Yangmei":1019,"Fugang":1020}
for x,y in StationList.items():
    name = str(x)
    id = str(y)
    if fromStation.lower() == name.lower():
        fromStation = id
    elif toStation.lower() == name.lower():
        toStation = id

print 'Class type'
print '[1] Express Class'
print '[2] Ordinary Class'
print '[3] All Types'
carClass = raw_input('Train class type (number) : ')
if carClass == '1':
    carClass = "'1100','1101','1102','1107','1108','1110','1120','1114','1115'"
elif carClass == '2':
    carClass = "'1131','1132','1140'"
else:
    carClass = '2'


enterTime = raw_input('Do you want to using today time or specify your time schedule ?( Y/N ) ')
date = datetime.now().strftime('%Y/%m/%d')
startTime = '0000'
endTime = '2359'
if enterTime.upper() == "Y":
    date = raw_input('Input Date (YYYY/MM/DD) : ')
    startTime = raw_input('Input departure time (HH:mm) : ')
    endTime = raw_input('Input arrival time (HH:mm) : ')

url = "http://twtraffic.tra.gov.tw/twrail/SearchResult.aspx?searchtype=0&searchdate=" + str(date) + "&fromstation=" + str(fromStation) + "&tostation=" + str(toStation) + "&trainclass=" + str(carClass) + "&fromtime=" + str(startTime).replace(":", "") +"&totime="+ str(endTime).replace(":", "") +"&language=eng"

webbrowser.open(url)