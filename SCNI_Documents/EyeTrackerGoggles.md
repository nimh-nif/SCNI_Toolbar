{\rtf1\ansi\ansicpg1252\cocoartf1504\cocoasubrtf830
{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww10800\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 The SCNI uses EyeLink II video-based eye tracking systems from [SR Research](http://www.sr-research.com/EL_II.html). While these systems are now over a decade old, this earlier 'primate mount' design is the only model available that uses light-weight cameras that can be mounted close to the subject, or even head mounted. The SCNI also uses 55" LG 4K OLED televisions with passive 3D for visual stimulation. In order to display stimuli stereoscopically, polarizing filters must be held in front of each of the subject's eyes. To achieve both of these goals, we designed a simple pair of goggles that can be positioned in front of a head-fixed animal during vision experiments.\
\
![Goggles](https://user-images.githubusercontent.com/7523776/31058012-c1d97f7c-a6ba-11e7-82cc-edae84d1ec9e.jpg)\
\
## Parts\
\
For the initial design, we used the following equipment to suspend the goggles in front of the animal by mounting it to the animal's chair:\
* Manfrotto 244N variable-friction magic arm ([B&H Photo](https://www.bhphotovideo.com/c/product/325444-REG/Manfrotto_244N_244N_Variable_Friction_Magic.html))\
* Manfrotto 035RL super clamp ([B&H Photo](https://www.bhphotovideo.com/c/product/546356-REG/Manfrotto_035RL_035RL_Super_Clamp_with.html))\
\
The following parts were ordered:\
* Nylon threaded rod, 8-32 ([McMaster-Carr](https://www.mcmaster.com/#standard-threaded-rods/=19kw5yo))\
* Nylon 8-32 hex nuts ([McMaster-Carr](https://www.mcmaster.com/#94812a400/=18o12ll))\
* Steel socket cap screw, 3/8"-16 thread size, 1" long ([McMaster-Carr](https://www.mcmaster.com/#92196a624/=19c8gb5))\
* 1/4"-20 hex nuts ([McMaster-Carr](https://www.mcmaster.com/#92673a113/=19kwa98))\
* 1/4"-20 slotted tripod screws, 12mm long ([B&H Photo](https://www.bhphotovideo.com/c/product/1049142-REG/desmond_5_sach14_knurled_1_4_20_slotted_screws.html))\
* High-performance hot mirror, 45\'b0 AOI, 101 x 127mm ([Edmund Optics](https://www.edmundoptics.com/optics/optical-mirrors/hot-cold-mirrors/45deg-aoi-101-x-127mm-hot-mirror/))\
\
We removed the polarizing filters from pairs of LG AG-F310 passive 3D glasses that came with the TVs (although other brands of passive 3D glasses with circular polarization could also work). Alternatively, if you want to present stereoscopic stimulation but do not have a passive 3D display then you could use anaglyph color filters instead.\
\
## Construction\
\
The main part of the goggles is 3D printed. We initially used the SCNI's Form2 from FormLabs, using the black V2 resin. The geometry of the part is robust enough for this material to work, although it is relatively brittle and will not tolerate being dropped or bumped very well. For future, head-mounted iterations we will therefore explore the use of 3D printed carbon-PEEK, for added strength and potentially reduced weight.\
\
## Towards a head-mounted design\
The current design weighs a total of XXXg (including cameras, excluding clamp and arm), making it too heavy for sustained use as a head-mounted device. Since the hot mirror and cameras contribute the majority of this weight, the ideal solution will be to use much smaller cameras that image the eye directly, eliminating the need for a mirror. This design is popular amongst commercial human head-mounted eye-tracking devices (e.g. ), but typically delivers lower frame rates (~60Hz vs 500Hz for EyeLink II) and requires customization for use in non-human subjects. }