# solar-viewer
To learn Elm http://elm-lang.org I decided to build a simple viewer for my newly installed Enphase Envoy solar panel array!

Update the URL in `getPanelData` at the bottom of `src/Main.elm` to point to your local Envoy's web server. Compile the file:

    elm make src/Main.elm --output=index.html

Then open `index.html` as a `file://` in your browser and enjoy! The graph (and numbers) update every minute.
## Screenshot
![Example Graph](https://github.com/seancorfield/solar-viewer/blob/master/screenshot.png)
