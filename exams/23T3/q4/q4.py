# a brief example, assuming table R(a,b,c)
import psycopg2
import sys

def printTimes(timeArray):
  formatted_times = []
  for i, time in enumerate(timeArray, start=1):
      formatted_times.append(f"t{i}={time}")
  print(", ".join(formatted_times))

def isImproving(timeArray):
  prev = timeArray[0]
  improving = True
  for x in timeArray[1:]:
    if x >= prev:
      improving = False
      break
    prev = x
  return improving

try:
   conn = psycopg2.connect("dbname=funrun")
except:
   print("Can't open database")
   exit()

person_name = sys.argv[1]

cur = conn.cursor()
query = '''select * from personExists(%s)'''
cur.execute(query, [person_name])
tuple, = cur.fetchone()
if not tuple:
  print('No such person')
  sys.exit()
query = '''select * from finishInfo(%s)'''
cur.execute(query, [person_name])
timeArray = []
for tuple in cur.fetchall():
  event_info, time, ordering = tuple
  timeArray.append(time)
if len(timeArray) == 1:
  printTimes(timeArray)
  print("Cannot determine a trend")
  sys.exit()
printTimes(timeArray)
if not isImproving(timeArray):
  print("Not improving")
else:
  print("Improving")

cur.close()
conn.close()

