fn JS.canvas_x () int
fn JS.canvas_y () int
fn JS.setpixel ( x int, y int, c u8 )
fn JS.settitle ( t &string )
fn JS.test     ( r &Rect )
fn JS.teststr  ( s &string )
fn JS.init     ( app &App )
fn JS.line     ( x0 u32, y0 u32, x1 u32, y1 u32, c u32 )

//@[heap]
struct App{
  mut: mousedown bool
       ox i32
       oy i32
       color u32
       //frame [ 320 * 200 ]u8
	frame [ 480 * 270 ]u8
}

struct Rect{
 x i32
 y i32
 w i32
 h i32
}

__global(
	rnd_next=u32 ( 0x1234 )
	app=App{}
)

fn rand() u32 { // RAND_MAX assumed to be 32767
    rnd_next = rnd_next * 1103515245 + 12345
    return (rnd_next >> 16) & 0x7fff
}

fn srand ( seed u32 ) {
    rnd_next = seed
}

fn fire ( t &u8 ) {
    unsafe {
        mut i:=0
        for i < 320 * 200 {
	    *t = 128
            t += 1
	    i += 1
        }
   }
}

pub fn (mut this App) draw () {
        mut x:= 0
        for x < 480 {
            unsafe {
                mut t:=&this.frame[0]+269*480+x
                    *t = u8( rand() )
                    //t+=320
                    //*t = u8( rand() )
                }
                x+=1
        }

	mut y:= 0
	for y < 270 - 1 {
	    x = 0
	    for x < 480 {
	        i:= x + y * 480
		unsafe {
		    // Te dwie linie nie generuje bledu
		    //t:=&app.frame[0]+i
		    //*t = u8(x*y)
		    // Ta linia generuje blad!
		    //*(i+&app.frame[0]) = 128

		    t0:= &app.frame[0]+i
		    t1:= &app.frame[0]+i-1+480
		    t2:= &app.frame[0]+i+0+480
		    t3:= &app.frame[0]+i+1+480
		    t4:= &app.frame[0]+i+480*2
		    *t0 = 32*(*t1 + *t2 + *t3 + *t4 )/129
		}
		x += 1
	    }
	    y += 1
	}
}

pub fn (mut app App) mousedown ( x i32,y i32 ) {
    app.mousedown=true
    app.ox=x
    app.oy=y
}

pub fn (mut app App) mouseup ( x i32, y i32 ) {
    app.mousedown=false
}


pub fn (mut this App) mousemove ( x i32, y i32 ) {
    if this.mousedown {
	unsafe {
	//JS.line ( app.ox, app.oy, x, y, app.color )
	dx:= app.ox - x
	dy:= app.oy - y
	w:= dx
	if w < 0 { w = -w }
	if dy < 0 {
	    if w < -dy { w = -dy }
	} else {
	    if w < dy { w = dy }
	}
	mut i:=0
	for i <= w {
	    p:= &this.frame[0] + x + (i*dy/w + y) * 480 + i*dx/w
            *p = 255
	    i+=1
	}
	this.ox = x
        this.oy = y
	}
    }
}

const key_1 = '1\000'
const key_2 = '2\000'
const key_shift = 'Shift\000'

pub fn (mut app App) keydown ( key &u8, code &u8 ) {
   println('V: keydown')
   unsafe{
	if cmp ( key, key_1.str ) { app.color = 0xff0000}
	else if cmp ( key, key_2.str ) { app.color = 0x00ff00}
	else if cmp ( key, key_shift.str ) { 
		println("V: Shift down")
	}
	else if cmp(code, code_backspace.str ) {
		JS.test( Rect{x:0,y:0,w:512,h:512} )
	}
   }
}


fn cmp( a &u8, b &u8 ) bool {  
   unsafe {
        for *a>0 && *b>0 {
		if *a!=*b { break }
		//println( string{a,1} )
		a+=1
		b+=1
        }
	return *a==*b
   }
}

const code_backspace = 'Backspace\000'
const code_shift_left = 'ShiftLeft\000'
const code_shift_right = 'ShiftRight\000'

pub fn (mut app App) keyup ( key &u8, code &u8 ) {
	if cmp ( code, code_shift_left.str ) {
		println ( code_shift_left )
	}
	if cmp ( code, code_shift_right.str ) {
		println ( code_shift_right )
	}
	println ( 'up' )
}

// `main` must be public!
pub fn main() {
	vwasm_memory_grow(2)

	title := "V WASM Fire demo"
	JS.settitle ( title )
	JS.init( app )

	app.draw()
}
