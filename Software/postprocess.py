def calculate_charge(start_time, end_time):
    duration = (end_time - start_time).total_seconds() / 60
    charge = duration * 0.25
    return charge