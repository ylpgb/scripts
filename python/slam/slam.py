#!/usr/bin/env python3

import numpy as np
import cv2
import sdl2
from display import Display
from extractor import Extractor

W=640
H=360

disp = Display(W, H)
orb = cv2.ORB_create()


      
fe = Extractor()
      
def process_frame(img):
   img = cv2.resize(img, (W,H))
   kps, des, matches = fe.extract(img)
   #if matches is None:
   #   return
   
   # , des = orb.detectAndCompute(img, None)
   for p in kps:
      u,v = map(lambda x: int(round(x)), p.pt)
      cv2.circle(img, (u,v), color=(0,255,0), radius=3)
      
   disp.point(img)
   
if __name__ == "__main__":
   cap = cv2.VideoCapture("test_countryroad.mp4")
   
   while cap.isOpened():
      ret, frame = cap.read()
      if ret == True:
         process_frame(frame)
      else:
         break;
