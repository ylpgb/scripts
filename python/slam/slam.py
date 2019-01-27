#!/usr/bin/env python3

import cv2
import sdl2
from display import Display

W=640
H=360

disp = Display(W, H)

def process_frame(img):
   img = cv2.resize(img, (W,H))
   disp.point(img)
   
if __name__ == "__main__":
   cap = cv2.VideoCapture("360p.mp4")
   
   while cap.isOpened():
      ret, frame = cap.read()
      if ret == True:
         process_frame(frame)
      else:
         break;
