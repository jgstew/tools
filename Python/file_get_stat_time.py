import os

file_stat_result = os.stat(os.path.abspath(__file__))

# print(file_stat_result)

file_stat_size = file_stat_result.st_size

print(f"file size: {file_stat_size}")

file_stat_times = [
    file_stat_result.st_atime,
    file_stat_result.st_ctime,
    file_stat_result.st_mtime,
]

print(file_stat_times)
