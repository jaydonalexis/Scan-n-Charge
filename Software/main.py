from fastapi import FastAPI, UploadFile, Response, File, Body
from fastapi.responses import FileResponse
import cv2
import numpy as np
import imageio
import uvicorn
import sqlite3
from datetime import datetime

import constants
import preprocess
import character_extraction
import server_response
import postprocess

def create_process_handler():
    matched_frames = 0
    blank_frames = 0
    previous_vertices = []
    remove_plate = False

    @app.post("/preprocess")
    async def process_image(file: UploadFile = File(...)):
        nonlocal matched_frames, blank_frames, previous_vertices, remove_plate
        content = await file.read()
        raw = np.frombuffer(content, dtype=np.uint8)
        raw = raw.reshape(constants.FRAME_PARAM)
        image = raw[:, :, 0:3]
        imageio.imwrite("image.png", image)
        image = cv2.imread("image.png")
        vertices, marked_image = preprocess.find_plate(image)
        matched_frames, previous_vertices, green_flag = preprocess.query_status(marked_image, vertices, previous_vertices, matched_frames)
        
        if not green_flag:
            blank_frames += 1

            if blank_frames > constants.MAX_BLANK_FRAMES:
                pass # Database removal logic

            blank_frames = 0

            return Response(content=b"", status_code=204)
        
        character_images, marked_image = character_extraction.read_plate(vertices, image)

        if(len(character_images) != constants.NUM_CHARS_BC):
            return Response(content=b"", status_code=204)
        
        server_response.prepare_response(character_images)
        directory = constants.BIN_FILE_DIRECTORY

        return FileResponse(f"{directory}/images.zip")
    
    @app.post("/postprocess")
    async def process_result(plate_number: str = Body()):
        current_time = datetime.now()
        cursor.execute(constants.SELECT_QUERY, (plate_number,))
        result = cursor.fetchone()

        if result:
            plate_number, start_time, _, _ = result
            end_time = current_time
            charge = postprocess.calculate_charge(start_time, end_time)
            cursor.execute(constants.UPDATE_QUERY, (end_time, charge, plate_number))
            file_name = f"log/{datetime.today().strftime('%Y-%m-%d')}.txt"

            with open(file_name, "a") as file:
                file.write(f"{plate_number} charged on {current_time} - Charge: {charge}\n")
        else:
            start_time = current_time
            cursor.execute(constants.INSERT_QUERY, (plate_number, start_time))

        db_connection.commit()
        return Response(content=b"", status_code=204)

if __name__ == "__main__":
    app = FastAPI()
    db_connection = sqlite3.connect('database/parking.db')
    cursor = db_connection.cursor()
    cursor.execute(constants.CREATE_TABLE_QUERY)
    db_connection.commit()
    # Create handler
    process_handler = create_process_handler()
    # Register the handler with the app
    app.add_route("/preprocess", process_handler)
    app.add_route("/postprocess", process_handler)
    uvicorn.run(app, host="0.0.0.0", port=8080)