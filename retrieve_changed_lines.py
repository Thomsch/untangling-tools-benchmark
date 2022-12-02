import sys
import json

# Exports line changed from smartcommit group
# # #G1.csv
# class, line
# class, line
# class, line

# #G2.csv
# class, line
# class, line
# class, line

def main():
    args = sys.argv[1:]

    if len(args) != 1:
        print("usage: export_group.py <path/to/group.json>")
        exit(1)
    
    print(args[0])
    with open(args[0]) as filename:
        data = json.load(filename)
        print(data)


if __name__ == "__main__":
    main()