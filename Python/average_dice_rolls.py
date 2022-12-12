import random


def dice_roll_text(num_sides=6, num_dice=1, modifier=0):
    mod_text = ""
    if modifier != 0:
        if modifier > 0:
            mod_text = "+" + str(modifier)
        else:
            mod_text = str(modifier)
    return str(num_dice) + "d" + str(num_sides) + mod_text


def average_dice_rolls(num_sides=6, num_dice=1, modifier=0, rolls=1000):
    total = 0
    for _ in range(rolls):
        roll = sum(random.randint(1, num_sides) for _ in range(num_dice))
        total += roll + modifier

    return round(total / rolls, 2)


def min_dice_roll(num_dice=1, modifier=0):
    return num_dice + modifier


def max_dice_roll(num_sides=6, num_dice=1, modifier=0):
    return num_dice * num_sides + modifier


def main():
    print("main()")

    die = [1, 2, 3]
    sides = [4, 6, 8, 10, 20]
    modifiers = [-1, 0, 1, 2]

    for dice in die:
        for side in sides:
            for mod in modifiers:
                print(
                    dice_roll_text(side, dice, mod)
                    + " min:"
                    + str(min_dice_roll(dice, mod))
                    + " avg:"
                    + str(average_dice_rolls(side, dice, mod))
                    + " max:"
                    + str(max_dice_roll(side, dice, mod))
                )


if __name__ == "__main__":
    main()
