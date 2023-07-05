import numpy as np
import os
import zipfile
import constants

def clean_directory():
    directory = constants.BIN_FILE_DIRECTORY

    for file_name in os.listdir(directory):
        file_path = os.path.join(directory, file_name)
        if os.path.isfile(file_path):
            os.remove(file_path)

def create_zip():
    directory = constants.BIN_FILE_DIRECTORY
    file_names = os.listdir(directory)

    with zipfile.ZipFile(f"{directory}/images.zip", "w") as zip:
        for file_name in file_names:
            file_path = os.path.join(directory, file_name)
            zip.write(file_path, arcname=file_name)

def convert_binary(images):
    clean_directory()

    for i, image in enumerate(images):
        modified_image = (image.flatten() / 255.0 * 65535.0).astype("int32")
        modified_image.tofile(f"{constants.BIN_FILE_DIRECTORY}/char{i + 1}.bin")

def prepare_response(images):
    ordered_images = []
    keys = sorted(images.keys(), reverse=False)

    for key in keys:
        ordered_images.append(images[key])

    convert_binary(ordered_images)
    create_zip()