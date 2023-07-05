import cv2
import numpy as np
import imutils
import math
import constants

def get_point_separation(p1, p2):
    return (((p2[0] - p1[0])**2)+((p2[1] - p1[1])**2))**0.5

def reorder_vertices(vertex_array):
    rearranged = np.roll(vertex_array, 1, axis=0)
    return rearranged

def get_vertex_angle(p1, p2, p3):
    l1= get_point_separation(p3, p2)
    l2= get_point_separation(p1, p3)
    l3= get_point_separation(p2, p1)

    try:
        angle = (math.acos((l1 + l3 - l2) / (2 * l3 * l2)) * 180.0) / math.pi
    except ValueError:
        angle=0
        
    return angle

def confirm_plate(p1, p2, threshold):
    return (p1 < p2 + threshold and p1 > p2 - threshold)

def query_status(marked_image, vertices, previous_vertices, matched_frames):
    if marked_image is None:
        previous_vertices = []
        matched_frames = 0
        green_flag = False
    else:
        green_flag = False

        if matched_frames > 0:
            plate_confirmed = True

            for i in range(len(vertices)):
                if not confirm_plate(vertices[i][0], previous_vertices[i][0], constants.DELTA_THRESHOLD):
                    plate_confirmed = False
                    break

            if plate_confirmed:
                previous_vertices = vertices
                matched_frames += 1

                if matched_frames == constants.FRAME_MATCH_TARGET:
                    previous_vertices = []
                    matched_frames = 0
                    green_flag = True
            else:
                previous_vertices = []
                matched_frames = 0
        else:
            previous_vertices = vertices
            matched_frames = 1

    return matched_frames, previous_vertices, green_flag

def change_perspective(vertices, image):
    original_points = np.float32([vertices])
    size_x = constants.LANDSCAPE_SIZE[0]
    size_y = constants.LANDSCAPE_SIZE[1]
    transformed_points = np.float32([[0, 0],[size_x, 0],[size_x, size_y],[0, size_y]])
    perspective_transform = cv2.getPerspectiveTransform(original_points, transformed_points)
    return cv2.warpPerspective(image, perspective_transform, constants.LANDSCAPE_SIZE)

def find_plate(image):
    vertices = []
    original_image = image.copy()
    # Convert to grayscale
    image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    # Apply bilateral filter to preserve and smooth out edges while reducing noise
    image = cv2.bilateralFilter(image, d=13, sigmaColor=15, sigmaSpace=15)
    # Apply Canny edge detection
    image = cv2.Canny(image, threshold1=20, threshold2=200)
    # structuring element used for dilation
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2, 2))
    # dilation expands edges and helps to connect nearby edge segments into larger contours
    image = cv2.dilate(image, kernel)
    # contours are curves or boundaries that join points having the same intensity and colour
    contours = imutils.grab_contours(cv2.findContours(image.copy(), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE))
    # sort the contours by area and grab the first 15 which is likely to contain the license plate contour
    contours = sorted(contours, key=cv2.contourArea, reverse=True)[:constants.MAX_CONTOURS]
    marked_image = None

    for contour in contours:
        perimeter = cv2.arcLength(contour, True)
        approximate = cv2.approxPolyDP(contour, constants.EPSILON_FACTOR * perimeter, True)
        
        if cv2.contourArea(contour) < (image.shape[0] * image.shape[1] * constants.FRAME_FILL):
            break;
    
        if len(approximate) == constants.NUM_SIDES:
            vertex_array = []

            for vertex in approximate:
                vertex_array.append(vertex[0])

            vertices = reorder_vertices(vertex_array)
            valid_angles = True

            for i in range(constants.NUM_SIDES):
                x, y, z = i % 4, (i + 1) % 4, (i + 2) % 4
                angle = get_vertex_angle(vertices[x], vertices[y], vertices[z])

                if angle > constants.MAX_ANGLE or angle < constants.MIN_ANGLE:
                    valid_angles = False
                    break

            if not valid_angles:
                continue

            marked_image = cv2.drawContours(original_image, [approximate], -1, (255, 0, 0), 2)
            cv2.imshow("Marked", marked_image)
            break

    return vertices, marked_image