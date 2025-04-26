from flask import Flask, request, jsonify
import cv2
import numpy as np
import pytesseract
import pyttsx3
import tensorflow as tf
import torch
from ultralytics import YOLO

# ========== INIT ==========
app = Flask(__name__)
engine = pyttsx3.init()

# Tesseract Path (change this for deployment)
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Load TFLite model for object detection
#interpreter = tf.lite.Interpreter(model_path="detect.tflite")
#interpreter.allocate_tensors()
#input_details = interpreter.get_input_details()
#output_details = interpreter.get_output_details()

# Load labels
#with open(r'C:\Users\Admin\OneDrive\Desktop\BLIND MINI\fomo\coco.names', 'r') as f:
#    labels = {i: line.strip() for i, line in enumerate(f)}

# Load YOLOv8 model
model = YOLO("yolov8n.pt")

# Scene Mapping
scene_mapping = {
    "person, chair, table, laptop": "Office",
    "sofa, TV, remote, lamp": "Living Room",
    "bed, pillow, lamp": "Bedroom",
    "stove, dining table, refrigerator, sink, microwave, bowl, cup, chair, bottle": "Kitchen",
    "car, bus, truck, motorcycle, bicycle": "Street",
    "tree, grass, bench": "Park",
    "handbag, suitcase, person, bottle, shopping cart": "Mall/Supermarket",
    "boat, bird, bench": "Lake/River",
    "traffic light, stop sign, fire hydrant": "Roadside",
    "keyboard, laptop, mouse": "Computer lab",
    "bed, person": "bedroom",

}

def infer_scene(detected_objects):
    detected_objects = set(detected_objects)
    for objects, scene in scene_mapping.items():
        obj_set = set(objects.split(", "))
        if obj_set.intersection(detected_objects):
            return scene
    return "Unknown Scene"

# ========== ROUTES ==========

@app.route('/process_image', methods=['POST'])
def process_image():
    try:
        file = request.files['image'].read()
        npimg = np.frombuffer(file, np.uint8)
        img = cv2.imdecode(npimg, cv2.IMREAD_COLOR)

        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        _, thresh = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        # Perform OCR
        text = pytesseract.image_to_string(thresh).strip()

        return jsonify({'text': text})
    except Exception as e:
        return jsonify({'error': str(e)})
    
"""  
@app.route('/detect', methods=['POST'])
def detect_objects():
    file = request.files['image']
    image = cv2.imdecode(np.frombuffer(file.read(), np.uint8), cv2.IMREAD_COLOR)
    img = cv2.resize(image, (300, 300))
    input_data = np.expand_dims(img, axis=0)
    input_data = ((input_data.astype(np.float32) - 127.5) / 127.5 * 255).astype(np.uint8)
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()

    boxes = interpreter.get_tensor(output_details[0]['index'])[0]
    classes = interpreter.get_tensor(output_details[1]['index'])[0]
    scores = interpreter.get_tensor(output_details[2]['index'])[0]

    detected_objects = []
    for i in range(len(scores)):
        if scores[i] > 0.5:
            label = labels.get(int(classes[i]), "Unknown")
            detected_objects.append(label)

    if detected_objects:
        engine.say(" and ".join(detected_objects))
        engine.runAndWait()

    return jsonify({"objects": detected_objects})
"""
    
@app.route('/scene_detect', methods=['POST'])
def detect_scene():
    if 'image' not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    image_file = request.files['image']
    image_path = "temp.jpg"
    image_file.save(image_path)

    # Load image
    image = cv2.imread(image_path)
    if image is None:
        return jsonify({"error": "Invalid image"}), 400

    # Perform object detection
    results = model(image)
    detected_objects = []

    for result in results:
        for box in result.boxes:
            cls = int(box.cls[0])  # Get class index
            obj_name = model.names.get(cls, "Unknown")  # Get object name safely
            detected_objects.append(obj_name)

    # Debugging: Print detected objects
    print("Detected Objects:", detected_objects)

    # Infer scene
    scene = infer_scene(detected_objects)

    return jsonify({
        "scene": scene,
        "detected_objects": detected_objects
    })
# ========== MAIN ==========
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
