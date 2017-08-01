#  AugmentedYellowPages

![](https://media.giphy.com/media/osTJRvSGBDjAA/giphy-downsized-large.gif)

This entire project was built on a Sunday as an exploration into the new ARKit framework of iOS 11. It is not meant as a production release what so ever, as such the code needs cleaned up. I wanted to see if I could plot nearby businesses using the [YellowPages API](http://yellowapi.com) and ARKit.
With the help of  [ARKit-CoreLocation](https://github.com/ProjectDent/ARKit-CoreLocation) by [Andrew Hart](https://twitter.com/andrewprojdent), plotting nodes to real-world coordinates was trivial. Be sure to check out that project, as you'll need it to compile this one! :)

## To get up & running:
### Set up ARCL using CocoaPods
1. Add to your podfile:

`pod 'ARCL'`

2. In Terminal, navigate to your project folder, then:

`pod update`

`pod install`

3. Add `NSCameraUsageDescription` and `NSLocationWhenInUseUsageDescription` to plist with a brief explanation (see demo project for an example)

### Modifying SceneLocationView.swift
Because I used a custom LocationNode class to allow me to draw text & an image inside a box, I needed to modify Andrew Hart's SceneLocationView class to support the updating of custom node objects, as it currently only supports his LocationAnnotationNode. Simple enough, just include a block as an instance variable to parse the new node.
1. Inside `SceneLocationView.swift` (and within the class itself) include the line:
```
public var customNodeUpdateBlock: ((LocationNode)->Void)?
```

2. Inside `SceneLocationView.updatePositionAndScaleOfLocationNode(locationNode: , initialSetup: , animated: , duration: )`, at the bottom ABOVE  `SCNTransaction.commit()`  include:

```
if let nodeBlock = customNodeUpdateBlock {
nodeBlock(locationNode)
}
```

### Register for a YellowPages API key
1. http://developer.yellowapi.com/apps/register
2. [FindBusinesses API Documentation](http://www.yellowapi.com/docs/places/)
3. Include your sandboxed API key in the `ViewController.swift` by replacing `YOUR-API-KEY-HERE` with your new API key from YellowAPI.com


## Bugs: There are plenty
- If you're too close to a nearby Restaurant, it will display the restaurant name as a massive text box on top of you.
- I was testing from home, with nearly all of the nearby restaurants being >500m away. Testing in a food court, all of the names appear in nearly the same position as the phone, greatly affecting readability of the signs.
- Feel free to adjust the scaling & distance values within ARCL's SceneLocationView class to your liking.
- Only searches YellowPages.com by using YellowAPI, often resulting in mismatched restaurants.
- It's pretty ugly. Sorry.
- Nearly non-existent error handling. Often just logs an error to the console.
- Lots more. This was a weekend project, and I'm genuinely impressed with how far I made it in a day. I might look at it again in the future.

## Who Am I
24 year old (currently) Indie iOS Developer from Ontario, Canada.
[@StephenHeaps](https://twitter.com/StephenHeaps)
