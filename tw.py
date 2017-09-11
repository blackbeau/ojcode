import collections
import sys
import datetime
class BoolInfo:
    def __init__(self, uid, startTime, endTime, courtNumber, isCancel):
      self.uid = uid
      self.startTime = startTime
      self.endTime = endTime
      self.startTime = startTime
      self.courtNumber = courtNumber
      if isCancel == "C":    
          self.isCancel = true
      else:
          self.isCancel = false
      
def validation( rawData ):
    dayTime = datetime.datetime.strptime(bookinfo[1], "%Y-%m-%d")
    startAndEndTime=bookinfo[2].split("~")
    if len(startAndEndTime) != 2:
        return false
    startTime = dayTime+datetime.datetime.strptime(startAndEndTime[0], "%H:%M")
    endTime = dayTime+datetime.datetime.strptime(startAndEndTime[1], "%H:%M")
    if bookinfo[3] not in ["A","B","C","D"]:
        return false
    if len(bookinfo) == bookinfo[4]!= "C":
        return false
    return BoolInfo(bookinfo[0],startTime,endTime,)
def addBookInfo( rawData ):
    if validation(bookinfo):
        pass
    else:
        print("Error: the booking is invalid!")
def cancelBookInfo( bookinfo ):
    
TimeTable={}
BookTable=collections.OrderedDict()
while True:
    rawData = input()
    if line == "":
        print(rawData)
        continue
    addBookInfo(rawData)                
