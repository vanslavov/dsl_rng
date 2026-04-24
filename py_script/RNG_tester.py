import sys
import serial
import numpy as np
import pyqtgraph as pg
from pyqtgraph.Qt import QtWidgets, QtCore
import time
import csv

SERIAL_PORT = 'COM3'
BAUD_RATE = 115200

UPDATE_INTERVAL_MS = 10
MAX_POINTS = 5000

OUTPUT_FILE = r"C:\Users\temp\Downloads\For UART testing\signal_log.csv"
BUFFER_SIZE = 2000

# ---------------- SERIAL ----------------
try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.1)
    use_serial = True
    print(f"Using serial port {SERIAL_PORT}")
except:
    use_serial = False
    print("Using dummy mode")

serial_buffer = bytearray()

# ---------------- CSV SETUP ----------------
csv_file = open(OUTPUT_FILE, mode='w', newline='')
writer = csv.writer(csv_file)
writer.writerow(["value"])  # ✅ only values now

write_buffer = []

# ---------------- GUI SETUP ----------------
app = QtWidgets.QApplication([])
win = pg.GraphicsLayoutWidget(title="Live Signal + Logging")
plot = win.addPlot(title="Signal")

plot.setLabel('bottom', "Time", units='s')
plot.setLabel('left', "Value")

curve = plot.plot(pen='y')
win.show()

# ---------------- DATA BUFFERS ----------------
signal_history = []
time_history = []

t0 = time.time()
total_samples = 0

# ---------------- UPDATE LOOP ----------------
def update():
    global serial_buffer, write_buffer, total_samples

    t_rel = time.time() - t0
    new_samples = []

    # -------- SERIAL READ --------
    if use_serial:
        data = ser.read(ser.in_waiting or 1)
        serial_buffer.extend(data)

        while True:
            start_idx = serial_buffer.find(b'\xAA')

            if start_idx == -1:
                serial_buffer.clear()
                break

            # Frame = AA + 4 bytes + FF
            if len(serial_buffer) < start_idx + 6:
                break

            if serial_buffer[start_idx + 5] == 0xFF:
                frame = serial_buffer[start_idx:start_idx + 6]

                # -------- 32-bit decode --------
                value = int.from_bytes(frame[1:5], byteorder='big', signed=False)

                new_samples.append(value)

                # Remove processed frame
                serial_buffer = serial_buffer[start_idx + 6:]

            else:
                serial_buffer = serial_buffer[start_idx + 1:]

    else:
        # dummy signal
        t = np.linspace(0, 2*np.pi, 20)
        new_samples = (2048 + 1000*np.sin(t)).tolist()

    # -------- UPDATE SYSTEM --------
    if new_samples:
        n = len(new_samples)
        dt = 1 / 1500  # sampling rate

        # ---- plot buffers ----
        signal_history.extend(new_samples)
        time_history.extend([t_rel + i * dt for i in range(n)])

        if len(signal_history) > MAX_POINTS:
            signal_history[:] = signal_history[-MAX_POINTS:]
            time_history[:] = time_history[-MAX_POINTS:]

        curve.setData(time_history, signal_history)

        # ---- logging buffer ----
        for i in range(n):
            total_samples += 1

            # safer printing (every 100 samples)
            if total_samples % 100 == 0:
                print(f"Data point # {total_samples}: {new_samples[i]} saved")

            write_buffer.append([new_samples[i]])  # ✅ only value stored

        # ---- buffered write ----
        if len(write_buffer) >= BUFFER_SIZE:
            writer.writerows(write_buffer)
            write_buffer.clear()

# ---------------- TIMER ----------------
timer = QtCore.QTimer()
timer.timeout.connect(update)
timer.start(UPDATE_INTERVAL_MS)

# ---------------- CLEAN EXIT ----------------
def cleanup():
    print("Closing...")
    if write_buffer:
        writer.writerows(write_buffer)
    csv_file.close()
    if use_serial:
        ser.close()

app.aboutToQuit.connect(cleanup)

sys.exit(app.exec())