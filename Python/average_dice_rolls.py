import random


def average_dice_rolls(num_dice, num_sides, modifier=0, rolls=1000):
    total = 0
    for _ in range(rolls):
        roll = sum(random.randint(1, num_sides) for _ in range(num_dice))
        total += roll + modifier

    return total / rolls


def main():
    print("main()")
    print(average_dice_rolls(1, 6))


if __name__ == "__main__":
    main()
