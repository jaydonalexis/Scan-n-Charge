DEBUG = False

# Pre-processing
MAX_BLANK_FRAMES = 10
EPSILON_FACTOR = 0.018
FRAME_FILL = 0.25
NUM_SIDES = 4
MAX_CONTOURS = 15
MAX_ANGLE = 100.0
MIN_ANGLE = 80.0
DELTA_THRESHOLD = 5
FRAME_MATCH_TARGET = 3
FRAME_PARAM = (640, 480, 4)
LANDSCAPE_SIZE = (533, 400)

# Character Extraction
LOWER_BOUND = [[0, 120, 0], [50, 120, 0]]
UPPER_BOUND = [[10, 255, 250], [360, 255, 250]]
PADDING = 6
MIN_HEIGHT_SCALE = 0.125
MAX_HEIGHT_SCALE = 0.5
MAX_WIDTH_SCALE = 0.5
MAX_ASPECT_RATIO = 1.333
MIN_RMSE_ERROR = 35
MAX_MEAN_HEIGHT_DEVIATION = 2.25

# Response Preparation
NUM_CHARS_BC = 6
BIN_FILE_DIRECTORY = "./response"

# Database
CREATE_TABLE_QUERY = '''
    CREATE TABLE IF NOT EXISTS parking (
        plate_number TEXT PRIMARY KEY,
        start_time TIMESTAMP,
        end_time TIMESTAMP,
        charged_amount REAL
    )
'''
SELECT_QUERY = 'SELECT * FROM parking WHERE plate_number = ?'
UPDATE_QUERY = 'UPDATE parking SET end_time = ?, charged_amount = ? WHERE plate_number = ?'
INSERT_QUERY = 'INSERT INTO parking (plate_number, start_time) VALUES (?, ?)'