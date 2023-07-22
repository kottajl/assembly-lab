# Ellipse Drawer

Second project for Assembly x86 Language laboratories 2022/23.

## How to use

Program accept an input in form: _\<number\> \<number\>_, where

* ***\<number\>*** is a number in range 0-200

Both of numbers are starting values of ellipse diameters (first one is horizontal and second one is vertical).
Correct ellipse will be displayed in 320x200 VGA mode.

User can change the parameters of the ellipse:
* **up_arrow** & **down_arrow** - change length of vertical diameter/radius
* **left_arrow** & **right_arrow** - change length of horizontal diameter/radius
* **digit keys from 0 to 6** - change color of the ellipse
* **'r' key** - reverse the ellipse (swap the values of diameters and shrink vertical one to fit the 320x200 display)
* **'x' key** - draw a maximal ellipse (320x200)

Press an **'Esc'** key to exit VGA mode and return to the text mode.