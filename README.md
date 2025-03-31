# OneFingerRotation-Remastered

OneFingerRotation-Remastered is a lightweight Swift Package that gives you the ability to rotate views at runtime using just one finger.

This package is an improved fork of [Matteo Fontana's OneFingerRotation](https://github.com/mttfntn/OneFingerRotation) that adds support for ProMotion refresh rates, Low Power Mode, and uses less energy to accomplish its goals.\
It is not a drop-in replacement, however, as the minimum OS requirements and the entire API have changed.

---

## Usage

This package adds one view modifier `.viewRotation()` that accepts a number of optional arguments that control the behavior of the modified view.

These are all the arguments with example values:

```swift
@State var angle: Angle = .zero

// ...

someView
	.viewRotation(
		rotationAngle: $angle,
		touchRotationEnabled: .constant(true),
		knobRange: Angle(degrees: -90)...Angle(degrees: 90),
		inertiaEnabled: .constant(true),
		inertiaFriction: .constant(1.5),
		autoRotationEnabled: .constant(false),
		autoRotationSpeed: .constant(.degrees(90))
	)
```

Below are some possible configurations that are possible with this package:

### Set-and-Forget Rotation

Use this if you *only* want rotation and nothing else. Just add `.viewRotation()` to a view and it will become rotatable with one finger.

### Rotation with a bound value

Use this if you want to act on certain rotation angles.

```swift
@State var rotation: Angle = .zero

someView
	.viewRotation(rotationAngle: $rotation)
```

### Rotation with Inertia

Use this if you want the ✨ *fanciest* ✨ rotation. Set `inertiaEnabled` to `true` and optionally override `inertiaFriction` to control how quickly the view's rotation slows down after flicking it.

**Note:** The default friction value is **1.5**.

```swift
@State var rotation: Angle = .zero
@State var inertiaEnabled: Angle = .constant(true)
@State var inertiaFriction: Double = 1.5

someView
	.viewRotation(
		rotationAngle: $totalAngle,
		inertiaEnabled: $inertiaEnabled,
		inertiaFriction: $inertiaFriction
	)
```

### Auto Rotation

Use this if you want a view that, in addition to the previous rotation modes, can *also* rotate on its own.

**Note:** By default, auto-rotating views rotate by **20 degrees per second**.

```swift
@State var rotation: Angle = .zero
@State var autoRotationEnabled: Angle = .constant(true)
@State var autoRotationSpeed: Angle = .constant(.degrees(20))

someView
	.viewRotation(
		rotationAngle: $totalAngle,
		autoRotationEnabled: $rotationEnabled,
		autoRotationSpeed: $rotationSpeed
	)
```

### Auto Rotation *only*

If you don't want your rotating view to be interrupted by a user, just set `touchRotationEnabled` to `false`.

**Note:** By default, touch rotation is **enabled**.

```swift
@State var rotation: Angle = .zero
@State var autoRotationEnabled: Angle = .constant(true)
@State var autoRotationSpeed: Angle = .constant(.degrees(20))

someView
	.viewRotation(
		rotationAngle: $totalAngle,
		touchRotationEnabled: .constant(false),
		autoRotationEnabled: $rotationEnabled,
		autoRotationSpeed: $rotationSpeed
	)
```

### Shortcuts

There is an additional overload to `.viewRotation` that takes a `Mode` enum. This enum enables easier, more readable view setup for a number of cases:

```swift
public enum Mode {
	case knob(range: ClosedRange<Angle>)
	case inertia(friction: Double)
	case autoRotation(speed: Angle)
	case autoRotationNoTouch(speed: Angle)
	case inertiaAndAutoRotation(friction: Double, speed: Angle)
}
```