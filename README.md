# BSTTabView

The BSTTabView is a custom control that implements a tab band to be located at
the top or bottom of another control.

It is a tab interface with arbitrary number of tabs. One and only one tab is
selected at any one time. The tabs are aligned with the top or bottom edge as
appropriate. 

The tabs will try to size themselves after the content but will autoshrink if
space is insufficient. Tab colors and shape can be configured (trapezoid or 
square with or without rounded corners) 

Clicking on a tab selects it. Doubleclicking can enable interactive edit of the
tab label. The tabView also implements visual rollovers for indication of possible 
click targets. Dragging of tabs for sorting can be enabled either internally
within the control or externally between different controls.  

The control implements both a simple target-action message and an optional 
extensive delegate protocol for interaction with its controller. 

The tab view control does not implement undo, but this can be achieved by 
the owning controller using the delegate protocol. 