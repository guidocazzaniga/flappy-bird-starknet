interface BirdPos {
    birdPos: number[]
}

export default function Bird(props: BirdPos) {

    const styleDot = {
        left: `${(5)}%`,
        bottom: `${(props.birdPos[1] - 2)}%`
    }
    return (
        <div>
            <div className="bird"/*"snake-dot"*/ style={styleDot}></div>

        </div>
    )
}