import random


def average_dice_rolls(num_sides=6, num_dice=1, modifier=0, rolls=1000):
    total = 0
    for _ in range(rolls):
        roll = sum(random.randint(1, num_sides) for _ in range(num_dice))
        total += roll + modifier

    return total / rolls


def min_dice_roll(num_dice=1, modifier=0):
    return num_dice + modifier


def max_dice_roll(num_sides=6, num_dice=1, modifier=0):
    return num_dice * num_sides + modifier


def main():
    print("main()")
    print(average_dice_rolls(6, 1))
    print(average_dice_rolls(6, 2))
    print(average_dice_rolls(6, 3))
    print(average_dice_rolls(8, 1))
    print(average_dice_rolls(8, 2))
    print(average_dice_rolls(8, 3))
    print(average_dice_rolls(10, 1))
    print(average_dice_rolls(10, 2))
    print(average_dice_rolls(10, 3))


if __name__ == "__main__":
    main()
