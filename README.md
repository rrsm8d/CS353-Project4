# CS353-Project4
This is a class project for a text-adventure game. The setting is a lab with a pedestal containing a gold bar and a large locked door. Your goal is to escape the lab with the gold bar.

There are multiple locations branching from the center lab. The end of each path contains a colored block which serves as a key for the pedestal

After obtaining all colored blocks, you are able to unlock the pedestal and door, while giving access to the gold bar.

Taking the gold bar locks the escape door. If you have found a jar along your path, you may drop the jar in-place of the gold bar to make it out with the gold for the good ending.

# How to run
1. Download both source files and open LabGameWorld.rkt in an IDE, such as DrRacket
2. Run the program
3. There is a list of commands by typing "help"

# Sources used
Matthew Flatt, 2011, Creating Languages in Racket. Volume 9, Issue 11. https://queue.acm.org/detail.cfm?id=2068896

# Sample outputs

## Start of program
![StartOutput](https://github.com/rrsm8d/CS353-Project4/assets/112575975/daa596c2-9504-4fa8-b15e-224230e9e52e)

## Movement and inventory

![MovementInventoryOutput](https://github.com/rrsm8d/CS353-Project4/assets/112575975/1033e156-229d-417e-9006-14c59cec1e87)

## Multiple endings

![BadEndingOutput](https://github.com/rrsm8d/CS353-Project4/assets/112575975/8a9d73e5-adca-48ca-9d60-1da3e7e6d5d5)
![GoodEndOutput](https://github.com/rrsm8d/CS353-Project4/assets/112575975/31e10c5a-7e9e-4f3a-be0f-e178223232e7)

## Randomization
![RandomizationOutput](https://github.com/rrsm8d/CS353-Project4/assets/112575975/f257a940-db07-4e3e-95e8-49e9db0cd436)

# Winning path
east

north

get red-block

south

west

north

get jar (repeatedly until success)

east

get blue-block

west

south

west

west

get green-block

east

east

insert pedestal

get gold-bar

drop jar

out
