# Lite2D

This project was created because I ran into (known) performance issues using Light2D nodes in Godot.  

The basic ideas is to use a Raycast2D to detect objects and tilesets and determine their distance from the light source (a 'Lite2D').  Then a shader is applied to those objects (changed every frame for objects, once for tilesets) to illuminate them according to some chosen parameters (color, distance, angle of light source) and features of the sprite (normal map).  

With the use of the shader, the lighting is highly customizable.  An example comparison to the Light2D node is shown below using art assets I made for an old project.  The redundant tiles and characters have identical normal maps.
![Alt text](Lite2DDemo.gif) 
