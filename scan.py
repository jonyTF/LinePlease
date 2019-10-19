from pyimagesearch.transform import four_point_transform
from skimage.filters import threshold_local
import numpy as np
import argparse
import cv2
import imutils

# Parse arguments
ap = argparse.ArgumentParser()
ap.add_argument('-i', '--image', required=True, help='Path to image to be scanned')
args = vars(ap.parse_args())

# Load image and resize
image = cv2.imread(args['image'])
ratio = image.shape[0] / 500.0
orig = image.copy()
image = imutils.resize(image, height=500)

# Convert image to grayscale and perform edge detection
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
gray = cv2.GaussianBlur(gray, (5, 5), 0)
edged = cv2.Canny(gray, 75, 200)

# Show original image and edge detected image
print('STEP 1: EDGE DETECTION')
cv2.imshow('Image', image)
cv2.imshow('Edged', edged)
cv2.waitKey(0)
cv2.destroyAllWindows()

# Find contours in edged image and keep only the largest ones
cnts = cv2.findContours(edged.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
cnts = imutils.grab_contours(cnts)
cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:5]


found = False
for c in cnts:
    # Approximate contour
    peri = cv2.arcLength(c, True)
    approx = cv2.approxPolyDP(c, 0.02 * peri, True)

    copy = image.copy()
    cv2.drawContours(copy, [approx], -1, (0, 255, 0), 2)
    cv2.imshow('approx', copy)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

    # If approx. contour has four points, then we have found the document
    if len(approx) == 4:
        screenCnt = approx
        found = True
        break

if not found: 
    print('Could not find document')
    exit()

# Show contour of paper
print('STEP 2: FIND CONTOURS')
cv2.drawContours(image, [screenCnt], -1, (0, 255, 0), 2)
cv2.imshow('Outline', image)
cv2.waitKey(0)
cv2.destroyAllWindows()

# Perspective transform
warped = four_point_transform(orig, screenCnt.reshape(4, 2) * ratio)

# Black and white feel
warped = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
T = threshold_local(warped, 11, method='gaussian', offset=10)
warped = (warped > T).astype('uint8') * 255

# Show original and final result
cv2.imshow('Original', imutils.resize(orig, height=650))
cv2.imshow('Final', imutils.resize(warped, height=650))
cv2.waitKey(0)
cv2.destroyAllWindows()