from pathlib import Path

import untangle


def tcx_to_csv(filepath):
    xml = untangle.parse(str(filepath))

    csv_path = Path(filepath.parent, f'{filepath.stem}.csv')

    with csv_path.open('w') as f:
        f.write(f'distance,altitude,latitude,longitude\n')

        for trackpoint in xml.TrainingCenterDatabase.Courses.Course.Track.Trackpoint:
            distance = trackpoint.DistanceMeters.cdata
            altitude = trackpoint.AltitudeMeters.cdata
            latitude = trackpoint.Position.LatitudeDegrees.cdata
            longitude = trackpoint.Position.LongitudeDegrees.cdata

            f.write(f'{distance},{altitude},{latitude},{longitude}\n')


def convert_tcx_files():
    course_dir = Path(Path('.').parent, 'data', 'courses')
    for tcx_file in course_dir.glob('*.tcx'):
        tcx_to_csv(tcx_file)


if __name__ == "__main__":
    convert_tcx_files()
