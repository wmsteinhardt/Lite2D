# Lite2D

(EDIT:  This is old - this is from the days of ~3.4 IIRC)

This project was created because I ran into (known) performance issues using Light2D nodes in Godot.  

The basic ideas is to use a Raycast2D to detect objects and tilesets and determine their distance from the light source (a 'Lite2D').  Then a shader is applied to those objects (changed every frame for objects, once for tilesets) to illuminate them according to some chosen parameters (color, distance, angle of light source) and features of the sprite (normal map).  

With the use of the shader, the lighting is highly customizable.  An example comparison to the Light2D node is shown below using art assets I made for an old project.  The redundant tiles and characters have identical normal maps.
![Alt text](Lite2DDemo.gif) 

There are some drawbacks to this approach - only one shader can be applied to an object, so as it stands objects can be lit by one source at a time.  This could be easily remedied by keeping track of how many light sources are illuminating a particular object and applying them each with the same shader.  
