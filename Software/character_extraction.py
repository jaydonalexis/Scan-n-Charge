import cv2
import numpy as np
import imutils
import constants
import preprocess

def ydiscard(x_points, y_points, h_points, yhat):
    deltas = abs(y_points - yhat)
    max_delta = np.argmax(deltas)
    x_points.pop(max_delta)
    y_points.pop(max_delta)
    h_points.pop(max_delta)

def process_letter(image):
    height = image.shape[0]
    width = image.shape[1]
    image = cv2.blur(image, (10, 10))
    max_dimension = max(height, width)
    vertical_border = int((max_dimension - height) / 2.0)
    horizontal_border = int((max_dimension - width) / 2.0)
    image = cv2.copyMakeBorder(image, vertical_border, vertical_border, horizontal_border, horizontal_border, cv2.BORDER_CONSTANT)
    image = cv2.resize(image, (28, 28))
    return image

def linear_fit(x_points, y_points):
    results = {}
    coefficients = np.polyfit(x_points, y_points, 1)
    poly_object = np.poly1d(coefficients)
    yhat = poly_object(x_points)
    results['yhat'] = yhat
    ybar = np.sum(y_points) / len(y_points)
    sse = np.sum((y_points - yhat)**2)
    rmse = abs(sse)**0.5
    results["sse"] = sse
    results["rmse"] = rmse
    return results

def remove_outliers(images, x_points, y_points, h_points):
    final_images = {}
    
    if len(x_points) == 0:
        return final_images
    
    fit_data = linear_fit(x_points, y_points)
    rmse = fit_data["rmse"]

    # Discard based on midpoint y values
    while rmse > constants.MIN_RMSE_ERROR:
        yhat = fit_data["yhat"]
        x_points, y_points, h_points = ydiscard(x_points, y_points, h_points, yhat)
        fit_data = linear_fit(x_points, y_points)
        rmse = fit_data["rmse"]

    # Discard based on heights
    discard = set()
    for i in range(len(h_points)):
        if abs(h_points[i] - np.mean(h_points)) > constants.MAX_MEAN_HEIGHT_DEVIATION * np.std(h_points):
            discard.add(i)

    for i, x_point in enumerate(x_points):
        if i not in discard:
            final_images[x_point] = images[x_point]

    return final_images

def extract_characters(image):
    marked_image = image.copy()

    # Transform to HSV color space
    image = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

    mask1 = cv2.inRange(image, np.array(constants.LOWER_BOUND[0]), np.array(constants.UPPER_BOUND[0]))
    mask2 = cv2.inRange(image, np.array(constants.LOWER_BOUND[1]), np.array(constants.UPPER_BOUND[1]))
    mask = cv2.bitwise_or(mask1, mask2)

    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (4, 4))
    image = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)

    contours = imutils.grab_contours(cv2.findContours(image, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE))
    contours = sorted(contours, key=cv2.contourArea, reverse=True)[:15]

    cv2.imshow('Dilated', image)

    image_height = marked_image.shape[0]
    image_width = marked_image.shape[1]
    x_points = []
    y_points = []
    h_points = []
    bounding_boxes = []
    images = {}
    y_midpoints = {}

    for contour in contours:
        x, y, w, h = cv2.boundingRect(contour)

        if h < image_height * constants.MIN_HEIGHT_SCALE or \
           h < w * constants.MAX_ASPECT_RATIO            or \
           h > image_height * constants.MAX_HEIGHT_SCALE or \
           w > image_width * constants.MAX_WIDTH_SCALE   or \
           w > h:
            continue

        x_min = max(x - constants.PADDING, 0)
        y_min = max(y - constants.PADDING, 0)
        x_max = min(x + w + constants.PADDING, image_width)
        y_max = min(y + h + constants.PADDING, image_height)

        valid = True

        for box in bounding_boxes:
            if (x_min >= box[0][0] and \
                y_min >= box[0][1] and \
                x_max <= box[1][0] and \
                y_max <= box[1][1]):
                valid = False
                break
        
        if valid:
            y_midpoint = int((y_min + y_max) / 2.0)
            x_midpoint = int((x_min + x_max) / 2.0)

            y_points.append(y_midpoint)
            x_points.append(x_midpoint)
            h_points.append(h)

            marked_image = cv2.circle(marked_image, (x_midpoint, y_midpoint), radius=0, color=(0, 0, 255), thickness=4)
            marked_image = cv2.rectangle(marked_image, (x_min, y_min), (x_max, y_max), (255, 0, 0), 2)

            bounding_boxes.append([(x_min, y_min), (x_max, y_max)])

            cropped_image = image[y_min:y_max, x_min:x_max]
            cropped_image = process_letter(cropped_image)

            images[x_midpoint] = cropped_image
            y_midpoints[x_midpoint] = y_midpoint

    cv2.imshow("Marked", marked_image)
    cv2.waitKey()   
    images = remove_outliers(images, x_points, y_points, h_points)
    return images, marked_image

def read_plate(vertices, image):
    image = preprocess.change_perspective(vertices, image)
    character_images = extract_characters(image)
    return character_images