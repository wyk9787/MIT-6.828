
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 60 79 11 f0       	mov    $0xf0117960,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 dc 33 00 00       	call   f0103439 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 81 04 00 00       	call   f01004e3 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 80 38 10 f0       	push   $0xf0103880
f010006f:	e8 7d 28 00 00       	call   f01028f1 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 26 10 00 00       	call   f010109f <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 11 07 00 00       	call   f0100797 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 64 79 11 f0 00 	cmpl   $0x0,0xf0117964
f010009a:	74 0f                	je     f01000ab <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009c:	83 ec 0c             	sub    $0xc,%esp
f010009f:	6a 00                	push   $0x0
f01000a1:	e8 f1 06 00 00       	call   f0100797 <monitor>
f01000a6:	83 c4 10             	add    $0x10,%esp
f01000a9:	eb f1                	jmp    f010009c <_panic+0x11>
{
	va_list ap;

	if (panicstr)
		goto dead;
	panicstr = fmt;
f01000ab:	89 35 64 79 11 f0    	mov    %esi,0xf0117964

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000b1:	fa                   	cli    
f01000b2:	fc                   	cld    

	va_start(ap, fmt);
f01000b3:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b6:	83 ec 04             	sub    $0x4,%esp
f01000b9:	ff 75 0c             	pushl  0xc(%ebp)
f01000bc:	ff 75 08             	pushl  0x8(%ebp)
f01000bf:	68 9b 38 10 f0       	push   $0xf010389b
f01000c4:	e8 28 28 00 00       	call   f01028f1 <cprintf>
	vcprintf(fmt, ap);
f01000c9:	83 c4 08             	add    $0x8,%esp
f01000cc:	53                   	push   %ebx
f01000cd:	56                   	push   %esi
f01000ce:	e8 f8 27 00 00       	call   f01028cb <vcprintf>
	cprintf("\n");
f01000d3:	c7 04 24 11 48 10 f0 	movl   $0xf0104811,(%esp)
f01000da:	e8 12 28 00 00       	call   f01028f1 <cprintf>
f01000df:	83 c4 10             	add    $0x10,%esp
f01000e2:	eb b8                	jmp    f010009c <_panic+0x11>

f01000e4 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e4:	55                   	push   %ebp
f01000e5:	89 e5                	mov    %esp,%ebp
f01000e7:	53                   	push   %ebx
f01000e8:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000eb:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ee:	ff 75 0c             	pushl  0xc(%ebp)
f01000f1:	ff 75 08             	pushl  0x8(%ebp)
f01000f4:	68 b3 38 10 f0       	push   $0xf01038b3
f01000f9:	e8 f3 27 00 00       	call   f01028f1 <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	53                   	push   %ebx
f0100102:	ff 75 10             	pushl  0x10(%ebp)
f0100105:	e8 c1 27 00 00       	call   f01028cb <vcprintf>
	cprintf("\n");
f010010a:	c7 04 24 11 48 10 f0 	movl   $0xf0104811,(%esp)
f0100111:	e8 db 27 00 00       	call   f01028f1 <cprintf>
	va_end(ap);
}
f0100116:	83 c4 10             	add    $0x10,%esp
f0100119:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011c:	c9                   	leave  
f010011d:	c3                   	ret    
	...

f0100120 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100120:	55                   	push   %ebp
f0100121:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100123:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100128:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100129:	a8 01                	test   $0x1,%al
f010012b:	74 0b                	je     f0100138 <serial_proc_data+0x18>
f010012d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100132:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100133:	0f b6 c0             	movzbl %al,%eax
}
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100138:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010013d:	eb f7                	jmp    f0100136 <serial_proc_data+0x16>

f010013f <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013f:	55                   	push   %ebp
f0100140:	89 e5                	mov    %esp,%ebp
f0100142:	53                   	push   %ebx
f0100143:	83 ec 04             	sub    $0x4,%esp
f0100146:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100148:	ff d3                	call   *%ebx
f010014a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010014d:	74 2d                	je     f010017c <cons_intr+0x3d>
		if (c == 0)
f010014f:	85 c0                	test   %eax,%eax
f0100151:	74 f5                	je     f0100148 <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f0100153:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100159:	8d 51 01             	lea    0x1(%ecx),%edx
f010015c:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100162:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f0100168:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010016e:	75 d8                	jne    f0100148 <cons_intr+0x9>
			cons.wpos = 0;
f0100170:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f0100177:	00 00 00 
f010017a:	eb cc                	jmp    f0100148 <cons_intr+0x9>
	}
}
f010017c:	83 c4 04             	add    $0x4,%esp
f010017f:	5b                   	pop    %ebx
f0100180:	5d                   	pop    %ebp
f0100181:	c3                   	ret    

f0100182 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100182:	55                   	push   %ebp
f0100183:	89 e5                	mov    %esp,%ebp
f0100185:	53                   	push   %ebx
f0100186:	83 ec 04             	sub    $0x4,%esp
f0100189:	ba 64 00 00 00       	mov    $0x64,%edx
f010018e:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f010018f:	a8 01                	test   $0x1,%al
f0100191:	0f 84 eb 00 00 00    	je     f0100282 <kbd_proc_data+0x100>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f0100197:	a8 20                	test   $0x20,%al
f0100199:	0f 85 ea 00 00 00    	jne    f0100289 <kbd_proc_data+0x107>
f010019f:	ba 60 00 00 00       	mov    $0x60,%edx
f01001a4:	ec                   	in     (%dx),%al
f01001a5:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001a7:	3c e0                	cmp    $0xe0,%al
f01001a9:	74 73                	je     f010021e <kbd_proc_data+0x9c>
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001ab:	84 c0                	test   %al,%al
f01001ad:	78 7d                	js     f010022c <kbd_proc_data+0xaa>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
		shift &= ~(shiftcode[data] | E0ESC);
		return 0;
	} else if (shift & E0ESC) {
f01001af:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001b5:	f6 c1 40             	test   $0x40,%cl
f01001b8:	74 0e                	je     f01001c8 <kbd_proc_data+0x46>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001ba:	83 c8 80             	or     $0xffffff80,%eax
f01001bd:	88 c2                	mov    %al,%dl
		shift &= ~E0ESC;
f01001bf:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001c2:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f01001c8:	0f b6 d2             	movzbl %dl,%edx
f01001cb:	0f b6 82 20 3a 10 f0 	movzbl -0xfefc5e0(%edx),%eax
f01001d2:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
	shift ^= togglecode[data];
f01001d8:	0f b6 8a 20 39 10 f0 	movzbl -0xfefc6e0(%edx),%ecx
f01001df:	31 c8                	xor    %ecx,%eax
f01001e1:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f01001e6:	89 c1                	mov    %eax,%ecx
f01001e8:	83 e1 03             	and    $0x3,%ecx
f01001eb:	8b 0c 8d 00 39 10 f0 	mov    -0xfefc700(,%ecx,4),%ecx
f01001f2:	8a 14 11             	mov    (%ecx,%edx,1),%dl
f01001f5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01001f8:	a8 08                	test   $0x8,%al
f01001fa:	74 0d                	je     f0100209 <kbd_proc_data+0x87>
		if ('a' <= c && c <= 'z')
f01001fc:	89 da                	mov    %ebx,%edx
f01001fe:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100201:	83 f9 19             	cmp    $0x19,%ecx
f0100204:	77 55                	ja     f010025b <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f0100206:	83 eb 20             	sub    $0x20,%ebx
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100209:	f7 d0                	not    %eax
f010020b:	a8 06                	test   $0x6,%al
f010020d:	75 08                	jne    f0100217 <kbd_proc_data+0x95>
f010020f:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100215:	74 51                	je     f0100268 <kbd_proc_data+0xe6>
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100217:	89 d8                	mov    %ebx,%eax
f0100219:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010021c:	c9                   	leave  
f010021d:	c3                   	ret    

	data = inb(KBDATAP);

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
f010021e:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f0100225:	bb 00 00 00 00       	mov    $0x0,%ebx
f010022a:	eb eb                	jmp    f0100217 <kbd_proc_data+0x95>
	} else if (data & 0x80) {
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010022c:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f0100232:	f6 c1 40             	test   $0x40,%cl
f0100235:	75 05                	jne    f010023c <kbd_proc_data+0xba>
f0100237:	83 e0 7f             	and    $0x7f,%eax
f010023a:	88 c2                	mov    %al,%dl
		shift &= ~(shiftcode[data] | E0ESC);
f010023c:	0f b6 d2             	movzbl %dl,%edx
f010023f:	8a 82 20 3a 10 f0    	mov    -0xfefc5e0(%edx),%al
f0100245:	83 c8 40             	or     $0x40,%eax
f0100248:	0f b6 c0             	movzbl %al,%eax
f010024b:	f7 d0                	not    %eax
f010024d:	21 c8                	and    %ecx,%eax
f010024f:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f0100254:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100259:	eb bc                	jmp    f0100217 <kbd_proc_data+0x95>

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
f010025b:	83 ea 41             	sub    $0x41,%edx
f010025e:	83 fa 19             	cmp    $0x19,%edx
f0100261:	77 a6                	ja     f0100209 <kbd_proc_data+0x87>
			c += 'a' - 'A';
f0100263:	83 c3 20             	add    $0x20,%ebx
f0100266:	eb a1                	jmp    f0100209 <kbd_proc_data+0x87>
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
f0100268:	83 ec 0c             	sub    $0xc,%esp
f010026b:	68 cd 38 10 f0       	push   $0xf01038cd
f0100270:	e8 7c 26 00 00       	call   f01028f1 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100275:	ba 92 00 00 00       	mov    $0x92,%edx
f010027a:	b0 03                	mov    $0x3,%al
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
f0100280:	eb 95                	jmp    f0100217 <kbd_proc_data+0x95>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100282:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f0100287:	eb 8e                	jmp    f0100217 <kbd_proc_data+0x95>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f0100289:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010028e:	eb 87                	jmp    f0100217 <kbd_proc_data+0x95>

f0100290 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100290:	55                   	push   %ebp
f0100291:	89 e5                	mov    %esp,%ebp
f0100293:	57                   	push   %edi
f0100294:	56                   	push   %esi
f0100295:	53                   	push   %ebx
f0100296:	83 ec 1c             	sub    $0x1c,%esp
f0100299:	89 c7                	mov    %eax,%edi
f010029b:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a0:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002a5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002aa:	eb 06                	jmp    f01002b2 <cons_putc+0x22>
f01002ac:	89 ca                	mov    %ecx,%edx
f01002ae:	ec                   	in     (%dx),%al
f01002af:	ec                   	in     (%dx),%al
f01002b0:	ec                   	in     (%dx),%al
f01002b1:	ec                   	in     (%dx),%al
f01002b2:	89 f2                	mov    %esi,%edx
f01002b4:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002b5:	a8 20                	test   $0x20,%al
f01002b7:	75 03                	jne    f01002bc <cons_putc+0x2c>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002b9:	4b                   	dec    %ebx
f01002ba:	75 f0                	jne    f01002ac <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002bc:	89 f8                	mov    %edi,%eax
f01002be:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c1:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002c6:	ee                   	out    %al,(%dx)
f01002c7:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002cc:	be 79 03 00 00       	mov    $0x379,%esi
f01002d1:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d6:	eb 06                	jmp    f01002de <cons_putc+0x4e>
f01002d8:	89 ca                	mov    %ecx,%edx
f01002da:	ec                   	in     (%dx),%al
f01002db:	ec                   	in     (%dx),%al
f01002dc:	ec                   	in     (%dx),%al
f01002dd:	ec                   	in     (%dx),%al
f01002de:	89 f2                	mov    %esi,%edx
f01002e0:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002e1:	84 c0                	test   %al,%al
f01002e3:	78 03                	js     f01002e8 <cons_putc+0x58>
f01002e5:	4b                   	dec    %ebx
f01002e6:	75 f0                	jne    f01002d8 <cons_putc+0x48>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002e8:	ba 78 03 00 00       	mov    $0x378,%edx
f01002ed:	8a 45 e7             	mov    -0x19(%ebp),%al
f01002f0:	ee                   	out    %al,(%dx)
f01002f1:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01002f6:	b0 0d                	mov    $0xd,%al
f01002f8:	ee                   	out    %al,(%dx)
f01002f9:	b0 08                	mov    $0x8,%al
f01002fb:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01002fc:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f0100302:	75 06                	jne    f010030a <cons_putc+0x7a>
		c |= 0x0700;
f0100304:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f010030a:	89 f8                	mov    %edi,%eax
f010030c:	0f b6 c0             	movzbl %al,%eax
f010030f:	83 f8 09             	cmp    $0x9,%eax
f0100312:	0f 84 b1 00 00 00    	je     f01003c9 <cons_putc+0x139>
f0100318:	83 f8 09             	cmp    $0x9,%eax
f010031b:	7e 70                	jle    f010038d <cons_putc+0xfd>
f010031d:	83 f8 0a             	cmp    $0xa,%eax
f0100320:	0f 84 96 00 00 00    	je     f01003bc <cons_putc+0x12c>
f0100326:	83 f8 0d             	cmp    $0xd,%eax
f0100329:	0f 85 d1 00 00 00    	jne    f0100400 <cons_putc+0x170>
		break;
	case '\n':
		crt_pos += CRT_COLS;
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010032f:	66 8b 0d 28 75 11 f0 	mov    0xf0117528,%cx
f0100336:	bb 50 00 00 00       	mov    $0x50,%ebx
f010033b:	89 c8                	mov    %ecx,%eax
f010033d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100342:	66 f7 f3             	div    %bx
f0100345:	29 d1                	sub    %edx,%ecx
f0100347:	66 89 0d 28 75 11 f0 	mov    %cx,0xf0117528
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010034e:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100355:	cf 07 
f0100357:	0f 87 c5 00 00 00    	ja     f0100422 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010035d:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100363:	b0 0e                	mov    $0xe,%al
f0100365:	89 ca                	mov    %ecx,%edx
f0100367:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100368:	8d 59 01             	lea    0x1(%ecx),%ebx
f010036b:	66 a1 28 75 11 f0    	mov    0xf0117528,%ax
f0100371:	66 c1 e8 08          	shr    $0x8,%ax
f0100375:	89 da                	mov    %ebx,%edx
f0100377:	ee                   	out    %al,(%dx)
f0100378:	b0 0f                	mov    $0xf,%al
f010037a:	89 ca                	mov    %ecx,%edx
f010037c:	ee                   	out    %al,(%dx)
f010037d:	a0 28 75 11 f0       	mov    0xf0117528,%al
f0100382:	89 da                	mov    %ebx,%edx
f0100384:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100385:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100388:	5b                   	pop    %ebx
f0100389:	5e                   	pop    %esi
f010038a:	5f                   	pop    %edi
f010038b:	5d                   	pop    %ebp
f010038c:	c3                   	ret    
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
		c |= 0x0700;

	switch (c & 0xff) {
f010038d:	83 f8 08             	cmp    $0x8,%eax
f0100390:	75 6e                	jne    f0100400 <cons_putc+0x170>
	case '\b':
		if (crt_pos > 0) {
f0100392:	66 a1 28 75 11 f0    	mov    0xf0117528,%ax
f0100398:	66 85 c0             	test   %ax,%ax
f010039b:	74 c0                	je     f010035d <cons_putc+0xcd>
			crt_pos--;
f010039d:	48                   	dec    %eax
f010039e:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003a4:	0f b7 c0             	movzwl %ax,%eax
f01003a7:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01003ad:	83 cf 20             	or     $0x20,%edi
f01003b0:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003b6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ba:	eb 92                	jmp    f010034e <cons_putc+0xbe>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003bc:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003c3:	50 
f01003c4:	e9 66 ff ff ff       	jmp    f010032f <cons_putc+0x9f>
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
		break;
	case '\t':
		cons_putc(' ');
f01003c9:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ce:	e8 bd fe ff ff       	call   f0100290 <cons_putc>
		cons_putc(' ');
f01003d3:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d8:	e8 b3 fe ff ff       	call   f0100290 <cons_putc>
		cons_putc(' ');
f01003dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e2:	e8 a9 fe ff ff       	call   f0100290 <cons_putc>
		cons_putc(' ');
f01003e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ec:	e8 9f fe ff ff       	call   f0100290 <cons_putc>
		cons_putc(' ');
f01003f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f6:	e8 95 fe ff ff       	call   f0100290 <cons_putc>
f01003fb:	e9 4e ff ff ff       	jmp    f010034e <cons_putc+0xbe>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100400:	66 a1 28 75 11 f0    	mov    0xf0117528,%ax
f0100406:	8d 50 01             	lea    0x1(%eax),%edx
f0100409:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f0100410:	0f b7 c0             	movzwl %ax,%eax
f0100413:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100419:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010041d:	e9 2c ff ff ff       	jmp    f010034e <cons_putc+0xbe>

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100422:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f0100427:	83 ec 04             	sub    $0x4,%esp
f010042a:	68 00 0f 00 00       	push   $0xf00
f010042f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100435:	52                   	push   %edx
f0100436:	50                   	push   %eax
f0100437:	e8 4a 30 00 00       	call   f0103486 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010043c:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100442:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100448:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010044e:	83 c4 10             	add    $0x10,%esp
f0100451:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100456:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100459:	39 d0                	cmp    %edx,%eax
f010045b:	75 f4                	jne    f0100451 <cons_putc+0x1c1>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010045d:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100464:	50 
f0100465:	e9 f3 fe ff ff       	jmp    f010035d <cons_putc+0xcd>

f010046a <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f010046a:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f0100471:	75 01                	jne    f0100474 <serial_intr+0xa>
		cons_intr(serial_proc_data);
}
f0100473:	c3                   	ret    
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100474:	55                   	push   %ebp
f0100475:	89 e5                	mov    %esp,%ebp
f0100477:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010047a:	b8 20 01 10 f0       	mov    $0xf0100120,%eax
f010047f:	e8 bb fc ff ff       	call   f010013f <cons_intr>
}
f0100484:	c9                   	leave  
f0100485:	eb ec                	jmp    f0100473 <serial_intr+0x9>

f0100487 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100487:	55                   	push   %ebp
f0100488:	89 e5                	mov    %esp,%ebp
f010048a:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010048d:	b8 82 01 10 f0       	mov    $0xf0100182,%eax
f0100492:	e8 a8 fc ff ff       	call   f010013f <cons_intr>
}
f0100497:	c9                   	leave  
f0100498:	c3                   	ret    

f0100499 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100499:	55                   	push   %ebp
f010049a:	89 e5                	mov    %esp,%ebp
f010049c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010049f:	e8 c6 ff ff ff       	call   f010046a <serial_intr>
	kbd_intr();
f01004a4:	e8 de ff ff ff       	call   f0100487 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004a9:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004ae:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004b4:	74 26                	je     f01004dc <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004b6:	8d 50 01             	lea    0x1(%eax),%edx
f01004b9:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004bf:	0f b6 80 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%eax
		if (cons.rpos == CONSBUFSIZE)
f01004c6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004cc:	74 02                	je     f01004d0 <cons_getc+0x37>
			cons.rpos = 0;
		return c;
	}
	return 0;
}
f01004ce:	c9                   	leave  
f01004cf:	c3                   	ret    

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004d0:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004d7:	00 00 00 
f01004da:	eb f2                	jmp    f01004ce <cons_getc+0x35>
		return c;
	}
	return 0;
f01004dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01004e1:	eb eb                	jmp    f01004ce <cons_getc+0x35>

f01004e3 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004e3:	55                   	push   %ebp
f01004e4:	89 e5                	mov    %esp,%ebp
f01004e6:	56                   	push   %esi
f01004e7:	53                   	push   %ebx
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004e8:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f01004ef:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01004f6:	5a a5 
	if (*cp != 0xA55A) {
f01004f8:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f01004fe:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100502:	0f 84 a2 00 00 00    	je     f01005aa <cons_init+0xc7>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100508:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f010050f:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100512:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100517:	b0 0e                	mov    $0xe,%al
f0100519:	8b 15 30 75 11 f0    	mov    0xf0117530,%edx
f010051f:	ee                   	out    %al,(%dx)
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
f0100520:	8d 4a 01             	lea    0x1(%edx),%ecx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100523:	89 ca                	mov    %ecx,%edx
f0100525:	ec                   	in     (%dx),%al
f0100526:	0f b6 c0             	movzbl %al,%eax
f0100529:	c1 e0 08             	shl    $0x8,%eax
f010052c:	89 c3                	mov    %eax,%ebx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010052e:	b0 0f                	mov    $0xf,%al
f0100530:	8b 15 30 75 11 f0    	mov    0xf0117530,%edx
f0100536:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100537:	89 ca                	mov    %ecx,%edx
f0100539:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010053a:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100540:	0f b6 c0             	movzbl %al,%eax
f0100543:	09 d8                	or     %ebx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100545:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010054b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100550:	b0 00                	mov    $0x0,%al
f0100552:	89 f2                	mov    %esi,%edx
f0100554:	ee                   	out    %al,(%dx)
f0100555:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010055a:	b0 80                	mov    $0x80,%al
f010055c:	ee                   	out    %al,(%dx)
f010055d:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100562:	b0 0c                	mov    $0xc,%al
f0100564:	89 da                	mov    %ebx,%edx
f0100566:	ee                   	out    %al,(%dx)
f0100567:	ba f9 03 00 00       	mov    $0x3f9,%edx
f010056c:	b0 00                	mov    $0x0,%al
f010056e:	ee                   	out    %al,(%dx)
f010056f:	ba fb 03 00 00       	mov    $0x3fb,%edx
f0100574:	b0 03                	mov    $0x3,%al
f0100576:	ee                   	out    %al,(%dx)
f0100577:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010057c:	b0 00                	mov    $0x0,%al
f010057e:	ee                   	out    %al,(%dx)
f010057f:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100584:	b0 01                	mov    $0x1,%al
f0100586:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100587:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010058c:	ec                   	in     (%dx),%al
f010058d:	88 c1                	mov    %al,%cl
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010058f:	3c ff                	cmp    $0xff,%al
f0100591:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f0100598:	89 f2                	mov    %esi,%edx
f010059a:	ec                   	in     (%dx),%al
f010059b:	89 da                	mov    %ebx,%edx
f010059d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010059e:	80 f9 ff             	cmp    $0xff,%cl
f01005a1:	74 22                	je     f01005c5 <cons_init+0xe2>
		cprintf("Serial port does not exist!\n");
}
f01005a3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01005a6:	5b                   	pop    %ebx
f01005a7:	5e                   	pop    %esi
f01005a8:	5d                   	pop    %ebp
f01005a9:	c3                   	ret    
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005aa:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005b1:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f01005b8:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005bb:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f01005c0:	e9 52 ff ff ff       	jmp    f0100517 <cons_init+0x34>
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
		cprintf("Serial port does not exist!\n");
f01005c5:	83 ec 0c             	sub    $0xc,%esp
f01005c8:	68 d9 38 10 f0       	push   $0xf01038d9
f01005cd:	e8 1f 23 00 00       	call   f01028f1 <cprintf>
f01005d2:	83 c4 10             	add    $0x10,%esp
}
f01005d5:	eb cc                	jmp    f01005a3 <cons_init+0xc0>

f01005d7 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005d7:	55                   	push   %ebp
f01005d8:	89 e5                	mov    %esp,%ebp
f01005da:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01005e0:	e8 ab fc ff ff       	call   f0100290 <cons_putc>
}
f01005e5:	c9                   	leave  
f01005e6:	c3                   	ret    

f01005e7 <getchar>:

int
getchar(void)
{
f01005e7:	55                   	push   %ebp
f01005e8:	89 e5                	mov    %esp,%ebp
f01005ea:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01005ed:	e8 a7 fe ff ff       	call   f0100499 <cons_getc>
f01005f2:	85 c0                	test   %eax,%eax
f01005f4:	74 f7                	je     f01005ed <getchar+0x6>
		/* do nothing */;
	return c;
}
f01005f6:	c9                   	leave  
f01005f7:	c3                   	ret    

f01005f8 <iscons>:

int
iscons(int fdnum)
{
f01005f8:	55                   	push   %ebp
f01005f9:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01005fb:	b8 01 00 00 00       	mov    $0x1,%eax
f0100600:	5d                   	pop    %ebp
f0100601:	c3                   	ret    
	...

f0100604 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100604:	55                   	push   %ebp
f0100605:	89 e5                	mov    %esp,%ebp
f0100607:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010060a:	68 20 3b 10 f0       	push   $0xf0103b20
f010060f:	68 3e 3b 10 f0       	push   $0xf0103b3e
f0100614:	68 43 3b 10 f0       	push   $0xf0103b43
f0100619:	e8 d3 22 00 00       	call   f01028f1 <cprintf>
f010061e:	83 c4 0c             	add    $0xc,%esp
f0100621:	68 1c 3c 10 f0       	push   $0xf0103c1c
f0100626:	68 4c 3b 10 f0       	push   $0xf0103b4c
f010062b:	68 43 3b 10 f0       	push   $0xf0103b43
f0100630:	e8 bc 22 00 00       	call   f01028f1 <cprintf>
f0100635:	83 c4 0c             	add    $0xc,%esp
f0100638:	68 55 3b 10 f0       	push   $0xf0103b55
f010063d:	68 71 3b 10 f0       	push   $0xf0103b71
f0100642:	68 43 3b 10 f0       	push   $0xf0103b43
f0100647:	e8 a5 22 00 00       	call   f01028f1 <cprintf>
	return 0;
}
f010064c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100651:	c9                   	leave  
f0100652:	c3                   	ret    

f0100653 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100653:	55                   	push   %ebp
f0100654:	89 e5                	mov    %esp,%ebp
f0100656:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100659:	68 7b 3b 10 f0       	push   $0xf0103b7b
f010065e:	e8 8e 22 00 00       	call   f01028f1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100663:	83 c4 08             	add    $0x8,%esp
f0100666:	68 0c 00 10 00       	push   $0x10000c
f010066b:	68 44 3c 10 f0       	push   $0xf0103c44
f0100670:	e8 7c 22 00 00       	call   f01028f1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100675:	83 c4 0c             	add    $0xc,%esp
f0100678:	68 0c 00 10 00       	push   $0x10000c
f010067d:	68 0c 00 10 f0       	push   $0xf010000c
f0100682:	68 6c 3c 10 f0       	push   $0xf0103c6c
f0100687:	e8 65 22 00 00       	call   f01028f1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010068c:	83 c4 0c             	add    $0xc,%esp
f010068f:	68 68 38 10 00       	push   $0x103868
f0100694:	68 68 38 10 f0       	push   $0xf0103868
f0100699:	68 90 3c 10 f0       	push   $0xf0103c90
f010069e:	e8 4e 22 00 00       	call   f01028f1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006a3:	83 c4 0c             	add    $0xc,%esp
f01006a6:	68 00 73 11 00       	push   $0x117300
f01006ab:	68 00 73 11 f0       	push   $0xf0117300
f01006b0:	68 b4 3c 10 f0       	push   $0xf0103cb4
f01006b5:	e8 37 22 00 00       	call   f01028f1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006ba:	83 c4 0c             	add    $0xc,%esp
f01006bd:	68 60 79 11 00       	push   $0x117960
f01006c2:	68 60 79 11 f0       	push   $0xf0117960
f01006c7:	68 d8 3c 10 f0       	push   $0xf0103cd8
f01006cc:	e8 20 22 00 00       	call   f01028f1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006d1:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01006d4:	b8 5f 7d 11 f0       	mov    $0xf0117d5f,%eax
f01006d9:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006de:	c1 f8 0a             	sar    $0xa,%eax
f01006e1:	50                   	push   %eax
f01006e2:	68 fc 3c 10 f0       	push   $0xf0103cfc
f01006e7:	e8 05 22 00 00       	call   f01028f1 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f1:	c9                   	leave  
f01006f2:	c3                   	ret    

f01006f3 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01006f3:	55                   	push   %ebp
f01006f4:	89 e5                	mov    %esp,%ebp
f01006f6:	57                   	push   %edi
f01006f7:	56                   	push   %esi
f01006f8:	53                   	push   %ebx
f01006f9:	83 ec 48             	sub    $0x48,%esp
  cprintf("Stack backtrace:\n");
f01006fc:	68 94 3b 10 f0       	push   $0xf0103b94
f0100701:	e8 eb 21 00 00       	call   f01028f1 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100706:	89 e8                	mov    %ebp,%eax
f0100708:	89 c6                	mov    %eax,%esi

  uint32_t ebp = read_ebp();
  uint32_t eip = *(uint32_t *)(ebp + 4); 
f010070a:	8b 78 04             	mov    0x4(%eax),%edi
  
  while(ebp != 0) {
f010070d:	83 c4 10             	add    $0x10,%esp
f0100710:	eb 74                	jmp    f0100786 <mon_backtrace+0x93>
    cprintf("  ebp %08x  eip %08x  args", ebp, eip);    
f0100712:	83 ec 04             	sub    $0x4,%esp
f0100715:	57                   	push   %edi
f0100716:	56                   	push   %esi
f0100717:	68 a6 3b 10 f0       	push   $0xf0103ba6
f010071c:	e8 d0 21 00 00       	call   f01028f1 <cprintf>

    struct Eipdebuginfo info;
    debuginfo_eip(eip, &info);
f0100721:	83 c4 08             	add    $0x8,%esp
f0100724:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100727:	50                   	push   %eax
f0100728:	57                   	push   %edi
f0100729:	e8 c7 22 00 00       	call   f01029f5 <debuginfo_eip>
f010072e:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100731:	8d 46 1c             	lea    0x1c(%esi),%eax
f0100734:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100737:	83 c4 10             	add    $0x10,%esp

    int i;
    for(i = 0; i < 5; i++)
      // Starting from ebp+8, ebp+12 ...
      cprintf(" %08x", *(uint32_t *)(ebp + 4 * (i+2)));   
f010073a:	83 ec 08             	sub    $0x8,%esp
f010073d:	ff 33                	pushl  (%ebx)
f010073f:	68 c1 3b 10 f0       	push   $0xf0103bc1
f0100744:	e8 a8 21 00 00       	call   f01028f1 <cprintf>
f0100749:	83 c3 04             	add    $0x4,%ebx

    struct Eipdebuginfo info;
    debuginfo_eip(eip, &info);

    int i;
    for(i = 0; i < 5; i++)
f010074c:	83 c4 10             	add    $0x10,%esp
f010074f:	3b 5d c4             	cmp    -0x3c(%ebp),%ebx
f0100752:	75 e6                	jne    f010073a <mon_backtrace+0x47>
      // Starting from ebp+8, ebp+12 ...
      cprintf(" %08x", *(uint32_t *)(ebp + 4 * (i+2)));   
    cprintf("\n");
f0100754:	83 ec 0c             	sub    $0xc,%esp
f0100757:	68 11 48 10 f0       	push   $0xf0104811
f010075c:	e8 90 21 00 00       	call   f01028f1 <cprintf>

    // Print function name and line number
    cprintf("         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, 
f0100761:	83 c4 08             	add    $0x8,%esp
f0100764:	2b 7d e0             	sub    -0x20(%ebp),%edi
f0100767:	57                   	push   %edi
f0100768:	ff 75 d8             	pushl  -0x28(%ebp)
f010076b:	ff 75 dc             	pushl  -0x24(%ebp)
f010076e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100771:	ff 75 d0             	pushl  -0x30(%ebp)
f0100774:	68 c7 3b 10 f0       	push   $0xf0103bc7
f0100779:	e8 73 21 00 00       	call   f01028f1 <cprintf>
        info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);

    // Update ebp and eip
    ebp = *(uint32_t *)ebp; 
f010077e:	8b 36                	mov    (%esi),%esi
    eip = *(uint32_t *)(ebp + 4);
f0100780:	8b 7e 04             	mov    0x4(%esi),%edi
f0100783:	83 c4 20             	add    $0x20,%esp
  cprintf("Stack backtrace:\n");

  uint32_t ebp = read_ebp();
  uint32_t eip = *(uint32_t *)(ebp + 4); 
  
  while(ebp != 0) {
f0100786:	85 f6                	test   %esi,%esi
f0100788:	75 88                	jne    f0100712 <mon_backtrace+0x1f>
    ebp = *(uint32_t *)ebp; 
    eip = *(uint32_t *)(ebp + 4);
  }
  
	return 0;
}
f010078a:	b8 00 00 00 00       	mov    $0x0,%eax
f010078f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100792:	5b                   	pop    %ebx
f0100793:	5e                   	pop    %esi
f0100794:	5f                   	pop    %edi
f0100795:	5d                   	pop    %ebp
f0100796:	c3                   	ret    

f0100797 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100797:	55                   	push   %ebp
f0100798:	89 e5                	mov    %esp,%ebp
f010079a:	57                   	push   %edi
f010079b:	56                   	push   %esi
f010079c:	53                   	push   %ebx
f010079d:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007a0:	68 28 3d 10 f0       	push   $0xf0103d28
f01007a5:	e8 47 21 00 00       	call   f01028f1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007aa:	c7 04 24 4c 3d 10 f0 	movl   $0xf0103d4c,(%esp)
f01007b1:	e8 3b 21 00 00       	call   f01028f1 <cprintf>
f01007b6:	83 c4 10             	add    $0x10,%esp
f01007b9:	eb 47                	jmp    f0100802 <monitor+0x6b>
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007bb:	83 ec 08             	sub    $0x8,%esp
f01007be:	0f be c0             	movsbl %al,%eax
f01007c1:	50                   	push   %eax
f01007c2:	68 e4 3b 10 f0       	push   $0xf0103be4
f01007c7:	e8 38 2c 00 00       	call   f0103404 <strchr>
f01007cc:	83 c4 10             	add    $0x10,%esp
f01007cf:	85 c0                	test   %eax,%eax
f01007d1:	74 0a                	je     f01007dd <monitor+0x46>
			*buf++ = 0;
f01007d3:	c6 03 00             	movb   $0x0,(%ebx)
f01007d6:	89 f7                	mov    %esi,%edi
f01007d8:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007db:	eb 68                	jmp    f0100845 <monitor+0xae>
		if (*buf == 0)
f01007dd:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007e0:	74 6f                	je     f0100851 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007e2:	83 fe 0f             	cmp    $0xf,%esi
f01007e5:	74 09                	je     f01007f0 <monitor+0x59>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
f01007e7:	8d 7e 01             	lea    0x1(%esi),%edi
f01007ea:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01007ee:	eb 37                	jmp    f0100827 <monitor+0x90>
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007f0:	83 ec 08             	sub    $0x8,%esp
f01007f3:	6a 10                	push   $0x10
f01007f5:	68 e9 3b 10 f0       	push   $0xf0103be9
f01007fa:	e8 f2 20 00 00       	call   f01028f1 <cprintf>
f01007ff:	83 c4 10             	add    $0x10,%esp
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f0100802:	83 ec 0c             	sub    $0xc,%esp
f0100805:	68 e0 3b 10 f0       	push   $0xf0103be0
f010080a:	e8 e9 29 00 00       	call   f01031f8 <readline>
f010080f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100811:	83 c4 10             	add    $0x10,%esp
f0100814:	85 c0                	test   %eax,%eax
f0100816:	74 ea                	je     f0100802 <monitor+0x6b>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100818:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010081f:	be 00 00 00 00       	mov    $0x0,%esi
f0100824:	eb 21                	jmp    f0100847 <monitor+0xb0>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100826:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100827:	8a 03                	mov    (%ebx),%al
f0100829:	84 c0                	test   %al,%al
f010082b:	74 18                	je     f0100845 <monitor+0xae>
f010082d:	83 ec 08             	sub    $0x8,%esp
f0100830:	0f be c0             	movsbl %al,%eax
f0100833:	50                   	push   %eax
f0100834:	68 e4 3b 10 f0       	push   $0xf0103be4
f0100839:	e8 c6 2b 00 00       	call   f0103404 <strchr>
f010083e:	83 c4 10             	add    $0x10,%esp
f0100841:	85 c0                	test   %eax,%eax
f0100843:	74 e1                	je     f0100826 <monitor+0x8f>
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100845:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100847:	8a 03                	mov    (%ebx),%al
f0100849:	84 c0                	test   %al,%al
f010084b:	0f 85 6a ff ff ff    	jne    f01007bb <monitor+0x24>
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;
f0100851:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100858:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100859:	85 f6                	test   %esi,%esi
f010085b:	74 a5                	je     f0100802 <monitor+0x6b>
f010085d:	bf 80 3d 10 f0       	mov    $0xf0103d80,%edi
f0100862:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100867:	83 ec 08             	sub    $0x8,%esp
f010086a:	ff 37                	pushl  (%edi)
f010086c:	ff 75 a8             	pushl  -0x58(%ebp)
f010086f:	e8 3c 2b 00 00       	call   f01033b0 <strcmp>
f0100874:	83 c4 10             	add    $0x10,%esp
f0100877:	85 c0                	test   %eax,%eax
f0100879:	74 21                	je     f010089c <monitor+0x105>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010087b:	43                   	inc    %ebx
f010087c:	83 c7 0c             	add    $0xc,%edi
f010087f:	83 fb 03             	cmp    $0x3,%ebx
f0100882:	75 e3                	jne    f0100867 <monitor+0xd0>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100884:	83 ec 08             	sub    $0x8,%esp
f0100887:	ff 75 a8             	pushl  -0x58(%ebp)
f010088a:	68 06 3c 10 f0       	push   $0xf0103c06
f010088f:	e8 5d 20 00 00       	call   f01028f1 <cprintf>
f0100894:	83 c4 10             	add    $0x10,%esp
f0100897:	e9 66 ff ff ff       	jmp    f0100802 <monitor+0x6b>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f010089c:	83 ec 04             	sub    $0x4,%esp
f010089f:	8d 04 1b             	lea    (%ebx,%ebx,1),%eax
f01008a2:	01 c3                	add    %eax,%ebx
f01008a4:	ff 75 08             	pushl  0x8(%ebp)
f01008a7:	8d 45 a8             	lea    -0x58(%ebp),%eax
f01008aa:	50                   	push   %eax
f01008ab:	56                   	push   %esi
f01008ac:	ff 14 9d 88 3d 10 f0 	call   *-0xfefc278(,%ebx,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008b3:	83 c4 10             	add    $0x10,%esp
f01008b6:	85 c0                	test   %eax,%eax
f01008b8:	0f 89 44 ff ff ff    	jns    f0100802 <monitor+0x6b>
				break;
	}
}
f01008be:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008c1:	5b                   	pop    %ebx
f01008c2:	5e                   	pop    %esi
f01008c3:	5f                   	pop    %edi
f01008c4:	5d                   	pop    %ebp
f01008c5:	c3                   	ret    
	...

f01008c8 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008c8:	55                   	push   %ebp
f01008c9:	89 e5                	mov    %esp,%ebp
f01008cb:	56                   	push   %esi
f01008cc:	53                   	push   %ebx
f01008cd:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008cf:	83 ec 0c             	sub    $0xc,%esp
f01008d2:	50                   	push   %eax
f01008d3:	e8 b0 1f 00 00       	call   f0102888 <mc146818_read>
f01008d8:	89 c3                	mov    %eax,%ebx
f01008da:	46                   	inc    %esi
f01008db:	89 34 24             	mov    %esi,(%esp)
f01008de:	e8 a5 1f 00 00       	call   f0102888 <mc146818_read>
f01008e3:	c1 e0 08             	shl    $0x8,%eax
f01008e6:	09 d8                	or     %ebx,%eax
}
f01008e8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01008eb:	5b                   	pop    %ebx
f01008ec:	5e                   	pop    %esi
f01008ed:	5d                   	pop    %ebp
f01008ee:	c3                   	ret    

f01008ef <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008ef:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f01008f6:	74 3c                	je     f0100934 <boot_alloc+0x45>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
  if(n == 0) {
f01008f8:	85 c0                	test   %eax,%eax
f01008fa:	74 4b                	je     f0100947 <boot_alloc+0x58>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008fc:	55                   	push   %ebp
f01008fd:	89 e5                	mov    %esp,%ebp
f01008ff:	83 ec 08             	sub    $0x8,%esp
  if(n == 0) {
    return nextfree;
  } else if (n > 0) {
    size_t size = ROUNDUP(n, PGSIZE);
    // Stores the return value
    char* ret = nextfree;
f0100902:	8b 0d 38 75 11 f0    	mov    0xf0117538,%ecx
	//
	// LAB 2: Your code here.
  if(n == 0) {
    return nextfree;
  } else if (n > 0) {
    size_t size = ROUNDUP(n, PGSIZE);
f0100908:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
    // Stores the return value
    char* ret = nextfree;
    nextfree += size;
f010090e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100914:	01 ca                	add    %ecx,%edx
f0100916:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010091c:	81 3d 68 79 11 f0 00 	cmpl   $0x400,0xf0117968
f0100923:	04 00 00 
f0100926:	76 25                	jbe    f010094d <boot_alloc+0x5e>
    if(nextfree >= (char*)KADDR(0x400000)) {
f0100928:	81 fa ff ff 3f f0    	cmp    $0xf03fffff,%edx
f010092e:	77 33                	ja     f0100963 <boot_alloc+0x74>
      panic("Out of memory in boot_alloc");
    }
    return ret;
f0100930:	89 c8                	mov    %ecx,%eax
  }

	return NULL;
}
f0100932:	c9                   	leave  
f0100933:	c3                   	ret    
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100934:	ba 5f 89 11 f0       	mov    $0xf011895f,%edx
f0100939:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010093f:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
f0100945:	eb b1                	jmp    f01008f8 <boot_alloc+0x9>
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
  if(n == 0) {
    return nextfree;
f0100947:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f010094c:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010094d:	68 00 00 40 00       	push   $0x400000
f0100952:	68 a4 3d 10 f0       	push   $0xf0103da4
f0100957:	6a 70                	push   $0x70
f0100959:	68 44 45 10 f0       	push   $0xf0104544
f010095e:	e8 28 f7 ff ff       	call   f010008b <_panic>
    size_t size = ROUNDUP(n, PGSIZE);
    // Stores the return value
    char* ret = nextfree;
    nextfree += size;
    if(nextfree >= (char*)KADDR(0x400000)) {
      panic("Out of memory in boot_alloc");
f0100963:	83 ec 04             	sub    $0x4,%esp
f0100966:	68 50 45 10 f0       	push   $0xf0104550
f010096b:	6a 71                	push   $0x71
f010096d:	68 44 45 10 f0       	push   $0xf0104544
f0100972:	e8 14 f7 ff ff       	call   f010008b <_panic>

f0100977 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100977:	89 d1                	mov    %edx,%ecx
f0100979:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f010097c:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010097f:	a8 01                	test   $0x1,%al
f0100981:	75 06                	jne    f0100989 <check_va2pa+0x12>
		return ~0;
f0100983:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100988:	c3                   	ret    
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100989:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010098e:	89 c1                	mov    %eax,%ecx
f0100990:	c1 e9 0c             	shr    $0xc,%ecx
f0100993:	3b 0d 68 79 11 f0    	cmp    0xf0117968,%ecx
f0100999:	73 1b                	jae    f01009b6 <check_va2pa+0x3f>
	if (!(p[PTX(va)] & PTE_P))
f010099b:	c1 ea 0c             	shr    $0xc,%edx
f010099e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009a4:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009ab:	a8 01                	test   $0x1,%al
f01009ad:	75 22                	jne    f01009d1 <check_va2pa+0x5a>
		return ~0;
f01009af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01009b4:	eb d2                	jmp    f0100988 <check_va2pa+0x11>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009b6:	55                   	push   %ebp
f01009b7:	89 e5                	mov    %esp,%ebp
f01009b9:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009bc:	50                   	push   %eax
f01009bd:	68 a4 3d 10 f0       	push   $0xf0103da4
f01009c2:	68 e3 02 00 00       	push   $0x2e3
f01009c7:	68 44 45 10 f0       	push   $0xf0104544
f01009cc:	e8 ba f6 ff ff       	call   f010008b <_panic>
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009d1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009d6:	eb b0                	jmp    f0100988 <check_va2pa+0x11>

f01009d8 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009d8:	55                   	push   %ebp
f01009d9:	89 e5                	mov    %esp,%ebp
f01009db:	57                   	push   %edi
f01009dc:	56                   	push   %esi
f01009dd:	53                   	push   %ebx
f01009de:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009e1:	84 c0                	test   %al,%al
f01009e3:	0f 85 50 02 00 00    	jne    f0100c39 <check_page_free_list+0x261>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01009e9:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f01009f0:	74 0a                	je     f01009fc <check_page_free_list+0x24>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009f2:	be 00 04 00 00       	mov    $0x400,%esi
f01009f7:	e9 98 02 00 00       	jmp    f0100c94 <check_page_free_list+0x2bc>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009fc:	83 ec 04             	sub    $0x4,%esp
f01009ff:	68 c8 3d 10 f0       	push   $0xf0103dc8
f0100a04:	68 24 02 00 00       	push   $0x224
f0100a09:	68 44 45 10 f0       	push   $0xf0104544
f0100a0e:	e8 78 f6 ff ff       	call   f010008b <_panic>
f0100a13:	50                   	push   %eax
f0100a14:	68 a4 3d 10 f0       	push   $0xf0103da4
f0100a19:	6a 52                	push   $0x52
f0100a1b:	68 6c 45 10 f0       	push   $0xf010456c
f0100a20:	e8 66 f6 ff ff       	call   f010008b <_panic>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a25:	8b 1b                	mov    (%ebx),%ebx
f0100a27:	85 db                	test   %ebx,%ebx
f0100a29:	74 41                	je     f0100a6c <check_page_free_list+0x94>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a2b:	89 d8                	mov    %ebx,%eax
f0100a2d:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100a33:	c1 f8 03             	sar    $0x3,%eax
f0100a36:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a39:	89 c2                	mov    %eax,%edx
f0100a3b:	c1 ea 16             	shr    $0x16,%edx
f0100a3e:	39 f2                	cmp    %esi,%edx
f0100a40:	73 e3                	jae    f0100a25 <check_page_free_list+0x4d>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a42:	89 c2                	mov    %eax,%edx
f0100a44:	c1 ea 0c             	shr    $0xc,%edx
f0100a47:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100a4d:	73 c4                	jae    f0100a13 <check_page_free_list+0x3b>
			memset(page2kva(pp), 0x97, 128);
f0100a4f:	83 ec 04             	sub    $0x4,%esp
f0100a52:	68 80 00 00 00       	push   $0x80
f0100a57:	68 97 00 00 00       	push   $0x97
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0100a5c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a61:	50                   	push   %eax
f0100a62:	e8 d2 29 00 00       	call   f0103439 <memset>
f0100a67:	83 c4 10             	add    $0x10,%esp
f0100a6a:	eb b9                	jmp    f0100a25 <check_page_free_list+0x4d>

	first_free_page = (char *) boot_alloc(0);
f0100a6c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a71:	e8 79 fe ff ff       	call   f01008ef <boot_alloc>
f0100a76:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a79:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a7f:	8b 0d 70 79 11 f0    	mov    0xf0117970,%ecx
		assert(pp < pages + npages);
f0100a85:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0100a8a:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a8d:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100a90:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a93:	be 00 00 00 00       	mov    $0x0,%esi
f0100a98:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a9b:	e9 c8 00 00 00       	jmp    f0100b68 <check_page_free_list+0x190>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aa0:	68 7a 45 10 f0       	push   $0xf010457a
f0100aa5:	68 86 45 10 f0       	push   $0xf0104586
f0100aaa:	68 3e 02 00 00       	push   $0x23e
f0100aaf:	68 44 45 10 f0       	push   $0xf0104544
f0100ab4:	e8 d2 f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100ab9:	68 9b 45 10 f0       	push   $0xf010459b
f0100abe:	68 86 45 10 f0       	push   $0xf0104586
f0100ac3:	68 3f 02 00 00       	push   $0x23f
f0100ac8:	68 44 45 10 f0       	push   $0xf0104544
f0100acd:	e8 b9 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ad2:	68 ec 3d 10 f0       	push   $0xf0103dec
f0100ad7:	68 86 45 10 f0       	push   $0xf0104586
f0100adc:	68 40 02 00 00       	push   $0x240
f0100ae1:	68 44 45 10 f0       	push   $0xf0104544
f0100ae6:	e8 a0 f5 ff ff       	call   f010008b <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100aeb:	68 af 45 10 f0       	push   $0xf01045af
f0100af0:	68 86 45 10 f0       	push   $0xf0104586
f0100af5:	68 43 02 00 00       	push   $0x243
f0100afa:	68 44 45 10 f0       	push   $0xf0104544
f0100aff:	e8 87 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b04:	68 c0 45 10 f0       	push   $0xf01045c0
f0100b09:	68 86 45 10 f0       	push   $0xf0104586
f0100b0e:	68 44 02 00 00       	push   $0x244
f0100b13:	68 44 45 10 f0       	push   $0xf0104544
f0100b18:	e8 6e f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b1d:	68 20 3e 10 f0       	push   $0xf0103e20
f0100b22:	68 86 45 10 f0       	push   $0xf0104586
f0100b27:	68 45 02 00 00       	push   $0x245
f0100b2c:	68 44 45 10 f0       	push   $0xf0104544
f0100b31:	e8 55 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b36:	68 d9 45 10 f0       	push   $0xf01045d9
f0100b3b:	68 86 45 10 f0       	push   $0xf0104586
f0100b40:	68 46 02 00 00       	push   $0x246
f0100b45:	68 44 45 10 f0       	push   $0xf0104544
f0100b4a:	e8 3c f5 ff ff       	call   f010008b <_panic>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b4f:	89 c3                	mov    %eax,%ebx
f0100b51:	c1 eb 0c             	shr    $0xc,%ebx
f0100b54:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100b57:	76 63                	jbe    f0100bbc <check_page_free_list+0x1e4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0100b59:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b5e:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100b61:	77 6b                	ja     f0100bce <check_page_free_list+0x1f6>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
		else
			++nfree_extmem;
f0100b63:	ff 45 d0             	incl   -0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b66:	8b 12                	mov    (%edx),%edx
f0100b68:	85 d2                	test   %edx,%edx
f0100b6a:	74 7b                	je     f0100be7 <check_page_free_list+0x20f>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b6c:	39 ca                	cmp    %ecx,%edx
f0100b6e:	0f 82 2c ff ff ff    	jb     f0100aa0 <check_page_free_list+0xc8>
		assert(pp < pages + npages);
f0100b74:	39 fa                	cmp    %edi,%edx
f0100b76:	0f 83 3d ff ff ff    	jae    f0100ab9 <check_page_free_list+0xe1>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b7c:	89 d0                	mov    %edx,%eax
f0100b7e:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b81:	a8 07                	test   $0x7,%al
f0100b83:	0f 85 49 ff ff ff    	jne    f0100ad2 <check_page_free_list+0xfa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b89:	c1 f8 03             	sar    $0x3,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b8c:	c1 e0 0c             	shl    $0xc,%eax
f0100b8f:	0f 84 56 ff ff ff    	je     f0100aeb <check_page_free_list+0x113>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b95:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b9a:	0f 84 64 ff ff ff    	je     f0100b04 <check_page_free_list+0x12c>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ba0:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ba5:	0f 84 72 ff ff ff    	je     f0100b1d <check_page_free_list+0x145>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bab:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bb0:	74 84                	je     f0100b36 <check_page_free_list+0x15e>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bb2:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bb7:	77 96                	ja     f0100b4f <check_page_free_list+0x177>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bb9:	46                   	inc    %esi
f0100bba:	eb aa                	jmp    f0100b66 <check_page_free_list+0x18e>

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bbc:	50                   	push   %eax
f0100bbd:	68 a4 3d 10 f0       	push   $0xf0103da4
f0100bc2:	6a 52                	push   $0x52
f0100bc4:	68 6c 45 10 f0       	push   $0xf010456c
f0100bc9:	e8 bd f4 ff ff       	call   f010008b <_panic>
		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bce:	68 44 3e 10 f0       	push   $0xf0103e44
f0100bd3:	68 86 45 10 f0       	push   $0xf0104586
f0100bd8:	68 47 02 00 00       	push   $0x247
f0100bdd:	68 44 45 10 f0       	push   $0xf0104544
f0100be2:	e8 a4 f4 ff ff       	call   f010008b <_panic>
f0100be7:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100bea:	85 f6                	test   %esi,%esi
f0100bec:	7e 19                	jle    f0100c07 <check_page_free_list+0x22f>
	assert(nfree_extmem > 0);
f0100bee:	85 db                	test   %ebx,%ebx
f0100bf0:	7e 2e                	jle    f0100c20 <check_page_free_list+0x248>

	cprintf("check_page_free_list() succeeded!\n");
f0100bf2:	83 ec 0c             	sub    $0xc,%esp
f0100bf5:	68 8c 3e 10 f0       	push   $0xf0103e8c
f0100bfa:	e8 f2 1c 00 00       	call   f01028f1 <cprintf>
}
f0100bff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c02:	5b                   	pop    %ebx
f0100c03:	5e                   	pop    %esi
f0100c04:	5f                   	pop    %edi
f0100c05:	5d                   	pop    %ebp
f0100c06:	c3                   	ret    
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c07:	68 f3 45 10 f0       	push   $0xf01045f3
f0100c0c:	68 86 45 10 f0       	push   $0xf0104586
f0100c11:	68 4f 02 00 00       	push   $0x24f
f0100c16:	68 44 45 10 f0       	push   $0xf0104544
f0100c1b:	e8 6b f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c20:	68 05 46 10 f0       	push   $0xf0104605
f0100c25:	68 86 45 10 f0       	push   $0xf0104586
f0100c2a:	68 50 02 00 00       	push   $0x250
f0100c2f:	68 44 45 10 f0       	push   $0xf0104544
f0100c34:	e8 52 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c39:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c3e:	85 c0                	test   %eax,%eax
f0100c40:	0f 84 b6 fd ff ff    	je     f01009fc <check_page_free_list+0x24>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c46:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c49:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c4c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c4f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c52:	89 c2                	mov    %eax,%edx
f0100c54:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c5a:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c60:	0f 95 c2             	setne  %dl
f0100c63:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c66:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c6a:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c6c:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c70:	8b 00                	mov    (%eax),%eax
f0100c72:	85 c0                	test   %eax,%eax
f0100c74:	75 dc                	jne    f0100c52 <check_page_free_list+0x27a>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c76:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c79:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c7f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c82:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c85:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c87:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c8a:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c8f:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c94:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100c9a:	e9 88 fd ff ff       	jmp    f0100a27 <check_page_free_list+0x4f>

f0100c9f <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c9f:	55                   	push   %ebp
f0100ca0:	89 e5                	mov    %esp,%ebp
f0100ca2:	57                   	push   %edi
f0100ca3:	56                   	push   %esi
f0100ca4:	53                   	push   %ebx
f0100ca5:	83 ec 0c             	sub    $0xc,%esp
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
  // Starting from 1
	for (i = 1; i < npages_basemem; i++) {
f0100ca8:	8b 1d 40 75 11 f0    	mov    0xf0117540,%ebx
f0100cae:	8b 35 3c 75 11 f0    	mov    0xf011753c,%esi
f0100cb4:	b2 00                	mov    $0x0,%dl
f0100cb6:	b8 01 00 00 00       	mov    $0x1,%eax
f0100cbb:	bf 01 00 00 00       	mov    $0x1,%edi
f0100cc0:	eb 22                	jmp    f0100ce4 <page_init+0x45>
		pages[i].pp_ref = 0;
f0100cc2:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100cc9:	89 d1                	mov    %edx,%ecx
f0100ccb:	03 0d 70 79 11 f0    	add    0xf0117970,%ecx
f0100cd1:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100cd7:	89 31                	mov    %esi,(%ecx)
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
  // Starting from 1
	for (i = 1; i < npages_basemem; i++) {
f0100cd9:	40                   	inc    %eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100cda:	89 d6                	mov    %edx,%esi
f0100cdc:	03 35 70 79 11 f0    	add    0xf0117970,%esi
f0100ce2:	89 fa                	mov    %edi,%edx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
  // Starting from 1
	for (i = 1; i < npages_basemem; i++) {
f0100ce4:	39 d8                	cmp    %ebx,%eax
f0100ce6:	72 da                	jb     f0100cc2 <page_init+0x23>
f0100ce8:	84 d2                	test   %dl,%dl
f0100cea:	75 45                	jne    f0100d31 <page_init+0x92>
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

  // Skip the middle IO hole by using boot_alloc to find the next free page
  size_t next_free_page = PADDR(boot_alloc(0)) / PGSIZE;
f0100cec:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cf1:	e8 f9 fb ff ff       	call   f01008ef <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100cf6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100cfb:	76 3c                	jbe    f0100d39 <page_init+0x9a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0100cfd:	05 00 00 00 10       	add    $0x10000000,%eax
f0100d02:	c1 e8 0c             	shr    $0xc,%eax
  pages[next_free_page].pp_link = &pages[npages_basemem-1];
f0100d05:	8b 0d 70 79 11 f0    	mov    0xf0117970,%ecx
f0100d0b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100d12:	8d 5c d9 f8          	lea    -0x8(%ecx,%ebx,8),%ebx
f0100d16:	89 1c 11             	mov    %ebx,(%ecx,%edx,1)
  page_free_list = &pages[next_free_page];
f0100d19:	89 d3                	mov    %edx,%ebx
f0100d1b:	03 1d 70 79 11 f0    	add    0xf0117970,%ebx
f0100d21:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c

  // Mark the rest of the pages unti napges
  for (i = next_free_page + 1; i < npages; i++) {
f0100d27:	40                   	inc    %eax
f0100d28:	b1 00                	mov    $0x0,%cl
f0100d2a:	be 01 00 00 00       	mov    $0x1,%esi
f0100d2f:	eb 38                	jmp    f0100d69 <page_init+0xca>
f0100d31:	89 35 3c 75 11 f0    	mov    %esi,0xf011753c
f0100d37:	eb b3                	jmp    f0100cec <page_init+0x4d>

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d39:	50                   	push   %eax
f0100d3a:	68 b0 3e 10 f0       	push   $0xf0103eb0
f0100d3f:	68 1a 01 00 00       	push   $0x11a
f0100d44:	68 44 45 10 f0       	push   $0xf0104544
f0100d49:	e8 3d f3 ff ff       	call   f010008b <_panic>
		pages[i].pp_ref = 0;
f0100d4e:	89 d1                	mov    %edx,%ecx
f0100d50:	03 0d 70 79 11 f0    	add    0xf0117970,%ecx
f0100d56:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100d5c:	89 19                	mov    %ebx,(%ecx)
  size_t next_free_page = PADDR(boot_alloc(0)) / PGSIZE;
  pages[next_free_page].pp_link = &pages[npages_basemem-1];
  page_free_list = &pages[next_free_page];

  // Mark the rest of the pages unti napges
  for (i = next_free_page + 1; i < npages; i++) {
f0100d5e:	40                   	inc    %eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100d5f:	89 d3                	mov    %edx,%ebx
f0100d61:	03 1d 70 79 11 f0    	add    0xf0117970,%ebx
f0100d67:	89 f1                	mov    %esi,%ecx
f0100d69:	83 c2 08             	add    $0x8,%edx
  size_t next_free_page = PADDR(boot_alloc(0)) / PGSIZE;
  pages[next_free_page].pp_link = &pages[npages_basemem-1];
  page_free_list = &pages[next_free_page];

  // Mark the rest of the pages unti napges
  for (i = next_free_page + 1; i < npages; i++) {
f0100d6c:	3b 05 68 79 11 f0    	cmp    0xf0117968,%eax
f0100d72:	72 da                	jb     f0100d4e <page_init+0xaf>
f0100d74:	84 c9                	test   %cl,%cl
f0100d76:	75 08                	jne    f0100d80 <page_init+0xe1>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
  }
}
f0100d78:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d7b:	5b                   	pop    %ebx
f0100d7c:	5e                   	pop    %esi
f0100d7d:	5f                   	pop    %edi
f0100d7e:	5d                   	pop    %ebp
f0100d7f:	c3                   	ret    
f0100d80:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
f0100d86:	eb f0                	jmp    f0100d78 <page_init+0xd9>

f0100d88 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d88:	55                   	push   %ebp
f0100d89:	89 e5                	mov    %esp,%ebp
f0100d8b:	53                   	push   %ebx
f0100d8c:	83 ec 04             	sub    $0x4,%esp
  // Acquire a page from page free list
  struct PageInfo* page = page_free_list;
f0100d8f:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
  if(page == NULL) return NULL; // We are out of memory
f0100d95:	85 db                	test   %ebx,%ebx
f0100d97:	74 13                	je     f0100dac <page_alloc+0x24>

  // Update the free list to point to next free page
  page_free_list = page_free_list->pp_link;
f0100d99:	8b 03                	mov    (%ebx),%eax
f0100d9b:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

  // Check for double-free bugs
  page->pp_link = NULL;
f0100da0:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

  if(alloc_flags & ALLOC_ZERO) {
f0100da6:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100daa:	75 07                	jne    f0100db3 <page_alloc+0x2b>
    memset(page2kva(page), '\0', PGSIZE);  
  }
  return page;
}
f0100dac:	89 d8                	mov    %ebx,%eax
f0100dae:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100db1:	c9                   	leave  
f0100db2:	c3                   	ret    
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100db3:	89 d8                	mov    %ebx,%eax
f0100db5:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100dbb:	c1 f8 03             	sar    $0x3,%eax
f0100dbe:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dc1:	89 c2                	mov    %eax,%edx
f0100dc3:	c1 ea 0c             	shr    $0xc,%edx
f0100dc6:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100dcc:	73 1a                	jae    f0100de8 <page_alloc+0x60>

  // Check for double-free bugs
  page->pp_link = NULL;

  if(alloc_flags & ALLOC_ZERO) {
    memset(page2kva(page), '\0', PGSIZE);  
f0100dce:	83 ec 04             	sub    $0x4,%esp
f0100dd1:	68 00 10 00 00       	push   $0x1000
f0100dd6:	6a 00                	push   $0x0
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0100dd8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ddd:	50                   	push   %eax
f0100dde:	e8 56 26 00 00       	call   f0103439 <memset>
f0100de3:	83 c4 10             	add    $0x10,%esp
f0100de6:	eb c4                	jmp    f0100dac <page_alloc+0x24>

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100de8:	50                   	push   %eax
f0100de9:	68 a4 3d 10 f0       	push   $0xf0103da4
f0100dee:	6a 52                	push   $0x52
f0100df0:	68 6c 45 10 f0       	push   $0xf010456c
f0100df5:	e8 91 f2 ff ff       	call   f010008b <_panic>

f0100dfa <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100dfa:	55                   	push   %ebp
f0100dfb:	89 e5                	mov    %esp,%ebp
f0100dfd:	83 ec 08             	sub    $0x8,%esp
f0100e00:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
  if(pp->pp_ref != 0 || pp->pp_link != NULL) {
f0100e03:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e08:	75 14                	jne    f0100e1e <page_free+0x24>
f0100e0a:	83 38 00             	cmpl   $0x0,(%eax)
f0100e0d:	75 0f                	jne    f0100e1e <page_free+0x24>
    panic("page_free() was called on invalid page");
  }
  pp->pp_link = page_free_list;
f0100e0f:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100e15:	89 10                	mov    %edx,(%eax)
  page_free_list = pp;
f0100e17:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100e1c:	c9                   	leave  
f0100e1d:	c3                   	ret    
{
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
  if(pp->pp_ref != 0 || pp->pp_link != NULL) {
    panic("page_free() was called on invalid page");
f0100e1e:	83 ec 04             	sub    $0x4,%esp
f0100e21:	68 d4 3e 10 f0       	push   $0xf0103ed4
f0100e26:	68 4f 01 00 00       	push   $0x14f
f0100e2b:	68 44 45 10 f0       	push   $0xf0104544
f0100e30:	e8 56 f2 ff ff       	call   f010008b <_panic>

f0100e35 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e35:	55                   	push   %ebp
f0100e36:	89 e5                	mov    %esp,%ebp
f0100e38:	83 ec 08             	sub    $0x8,%esp
f0100e3b:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100e3e:	8b 42 04             	mov    0x4(%edx),%eax
f0100e41:	48                   	dec    %eax
f0100e42:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100e46:	66 85 c0             	test   %ax,%ax
f0100e49:	74 02                	je     f0100e4d <page_decref+0x18>
		page_free(pp);
}
f0100e4b:	c9                   	leave  
f0100e4c:	c3                   	ret    
//
void
page_decref(struct PageInfo* pp)
{
	if (--pp->pp_ref == 0)
		page_free(pp);
f0100e4d:	83 ec 0c             	sub    $0xc,%esp
f0100e50:	52                   	push   %edx
f0100e51:	e8 a4 ff ff ff       	call   f0100dfa <page_free>
f0100e56:	83 c4 10             	add    $0x10,%esp
}
f0100e59:	eb f0                	jmp    f0100e4b <page_decref+0x16>

f0100e5b <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e5b:	55                   	push   %ebp
f0100e5c:	89 e5                	mov    %esp,%ebp
f0100e5e:	56                   	push   %esi
f0100e5f:	53                   	push   %ebx
f0100e60:	8b 45 0c             	mov    0xc(%ebp),%eax
  size_t pgdir_index = PDX(va);
f0100e63:	89 c3                	mov    %eax,%ebx
f0100e65:	c1 eb 16             	shr    $0x16,%ebx
  pde_t pgdir_entry = pgdir[pgdir_index];
f0100e68:	c1 e3 02             	shl    $0x2,%ebx
f0100e6b:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e6e:	8b 13                	mov    (%ebx),%edx
  size_t pgtable_index = PTX(va);
f0100e70:	c1 e8 0c             	shr    $0xc,%eax
f0100e73:	25 ff 03 00 00       	and    $0x3ff,%eax
f0100e78:	89 c6                	mov    %eax,%esi

  // If pde exists
  if((pgdir_entry & PTE_P) == 1) {
f0100e7a:	f6 c2 01             	test   $0x1,%dl
f0100e7d:	74 36                	je     f0100eb5 <pgdir_walk+0x5a>
    pte_t *pgtable = (pte_t *)KADDR(PTE_ADDR(pgdir_entry));  
f0100e7f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e85:	89 d0                	mov    %edx,%eax
f0100e87:	c1 e8 0c             	shr    $0xc,%eax
f0100e8a:	39 05 68 79 11 f0    	cmp    %eax,0xf0117968
f0100e90:	76 0e                	jbe    f0100ea0 <pgdir_walk+0x45>
    return &pgtable[pgtable_index];
f0100e92:	8d 84 b2 00 00 00 f0 	lea    -0x10000000(%edx,%esi,4),%eax
    // Set the permission for the page we just allocated
    pgdir[pgdir_index] = page2pa(page) | PTE_P | PTE_W | PTE_U;  
    return (pte_t *)page2kva(page) + pgtable_index;
  }
	return NULL;
}
f0100e99:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e9c:	5b                   	pop    %ebx
f0100e9d:	5e                   	pop    %esi
f0100e9e:	5d                   	pop    %ebp
f0100e9f:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ea0:	52                   	push   %edx
f0100ea1:	68 a4 3d 10 f0       	push   $0xf0103da4
f0100ea6:	68 7f 01 00 00       	push   $0x17f
f0100eab:	68 44 45 10 f0       	push   $0xf0104544
f0100eb0:	e8 d6 f1 ff ff       	call   f010008b <_panic>
  // If pde exists
  if((pgdir_entry & PTE_P) == 1) {
    pte_t *pgtable = (pte_t *)KADDR(PTE_ADDR(pgdir_entry));  
    return &pgtable[pgtable_index];
  } else { // If pde doesn't exist
    if(!create) return NULL;
f0100eb5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100eb9:	74 5c                	je     f0100f17 <pgdir_walk+0xbc>
    // Zero out the page we allocate
    struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0100ebb:	83 ec 0c             	sub    $0xc,%esp
f0100ebe:	6a 01                	push   $0x1
f0100ec0:	e8 c3 fe ff ff       	call   f0100d88 <page_alloc>
    if(page == NULL) return NULL;
f0100ec5:	83 c4 10             	add    $0x10,%esp
f0100ec8:	85 c0                	test   %eax,%eax
f0100eca:	74 55                	je     f0100f21 <pgdir_walk+0xc6>

    // Increment the reference
    page->pp_ref++;
f0100ecc:	66 ff 40 04          	incw   0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ed0:	89 c2                	mov    %eax,%edx
f0100ed2:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0100ed8:	c1 fa 03             	sar    $0x3,%edx
f0100edb:	c1 e2 0c             	shl    $0xc,%edx
    // Set the permission for the page we just allocated
    pgdir[pgdir_index] = page2pa(page) | PTE_P | PTE_W | PTE_U;  
f0100ede:	83 ca 07             	or     $0x7,%edx
f0100ee1:	89 13                	mov    %edx,(%ebx)
f0100ee3:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0100ee9:	c1 f8 03             	sar    $0x3,%eax
f0100eec:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eef:	89 c2                	mov    %eax,%edx
f0100ef1:	c1 ea 0c             	shr    $0xc,%edx
f0100ef4:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0100efa:	73 09                	jae    f0100f05 <pgdir_walk+0xaa>
    return (pte_t *)page2kva(page) + pgtable_index;
f0100efc:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100f03:	eb 94                	jmp    f0100e99 <pgdir_walk+0x3e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f05:	50                   	push   %eax
f0100f06:	68 a4 3d 10 f0       	push   $0xf0103da4
f0100f0b:	6a 52                	push   $0x52
f0100f0d:	68 6c 45 10 f0       	push   $0xf010456c
f0100f12:	e8 74 f1 ff ff       	call   f010008b <_panic>
  // If pde exists
  if((pgdir_entry & PTE_P) == 1) {
    pte_t *pgtable = (pte_t *)KADDR(PTE_ADDR(pgdir_entry));  
    return &pgtable[pgtable_index];
  } else { // If pde doesn't exist
    if(!create) return NULL;
f0100f17:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f1c:	e9 78 ff ff ff       	jmp    f0100e99 <pgdir_walk+0x3e>
    // Zero out the page we allocate
    struct PageInfo *page = page_alloc(ALLOC_ZERO);
    if(page == NULL) return NULL;
f0100f21:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f26:	e9 6e ff ff ff       	jmp    f0100e99 <pgdir_walk+0x3e>

f0100f2b <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f2b:	55                   	push   %ebp
f0100f2c:	89 e5                	mov    %esp,%ebp
f0100f2e:	57                   	push   %edi
f0100f2f:	56                   	push   %esi
f0100f30:	53                   	push   %ebx
f0100f31:	83 ec 1c             	sub    $0x1c,%esp
f0100f34:	89 c7                	mov    %eax,%edi
  size_t page_num = PGNUM(size);
f0100f36:	c1 e9 0c             	shr    $0xc,%ecx
f0100f39:	89 4d e4             	mov    %ecx,-0x1c(%ebp)

  size_t i;
  for(i = 0; i < page_num; i++) {
f0100f3c:	89 d3                	mov    %edx,%ebx
f0100f3e:	be 00 00 00 00       	mov    $0x0,%esi
    pte_t* pgtable_entry = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true); 
    *pgtable_entry = (pa + i * PGSIZE) | perm | PTE_P;
f0100f43:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f46:	29 d0                	sub    %edx,%eax
f0100f48:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f4b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f4e:	83 c8 01             	or     $0x1,%eax
f0100f51:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
  size_t page_num = PGNUM(size);

  size_t i;
  for(i = 0; i < page_num; i++) {
f0100f54:	eb 21                	jmp    f0100f77 <boot_map_region+0x4c>
    pte_t* pgtable_entry = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true); 
f0100f56:	83 ec 04             	sub    $0x4,%esp
f0100f59:	6a 01                	push   $0x1
f0100f5b:	53                   	push   %ebx
f0100f5c:	57                   	push   %edi
f0100f5d:	e8 f9 fe ff ff       	call   f0100e5b <pgdir_walk>
    *pgtable_entry = (pa + i * PGSIZE) | perm | PTE_P;
f0100f62:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f65:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f0100f68:	0b 55 dc             	or     -0x24(%ebp),%edx
f0100f6b:	89 10                	mov    %edx,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
  size_t page_num = PGNUM(size);

  size_t i;
  for(i = 0; i < page_num; i++) {
f0100f6d:	46                   	inc    %esi
f0100f6e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f74:	83 c4 10             	add    $0x10,%esp
f0100f77:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100f7a:	75 da                	jne    f0100f56 <boot_map_region+0x2b>
    pte_t* pgtable_entry = pgdir_walk(pgdir, (char *)(va + i * PGSIZE), true); 
    *pgtable_entry = (pa + i * PGSIZE) | perm | PTE_P;
  }
}
f0100f7c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f7f:	5b                   	pop    %ebx
f0100f80:	5e                   	pop    %esi
f0100f81:	5f                   	pop    %edi
f0100f82:	5d                   	pop    %ebp
f0100f83:	c3                   	ret    

f0100f84 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f84:	55                   	push   %ebp
f0100f85:	89 e5                	mov    %esp,%ebp
f0100f87:	53                   	push   %ebx
f0100f88:	83 ec 08             	sub    $0x8,%esp
f0100f8b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  pte_t* pgtable_entry = pgdir_walk(pgdir, va, false);
f0100f8e:	6a 00                	push   $0x0
f0100f90:	ff 75 0c             	pushl  0xc(%ebp)
f0100f93:	ff 75 08             	pushl  0x8(%ebp)
f0100f96:	e8 c0 fe ff ff       	call   f0100e5b <pgdir_walk>
  // Check to see if thie pte is allocated and present
  if(pgtable_entry == NULL || (*pgtable_entry & PTE_P) != 1) return NULL;
f0100f9b:	83 c4 10             	add    $0x10,%esp
f0100f9e:	85 c0                	test   %eax,%eax
f0100fa0:	74 3a                	je     f0100fdc <page_lookup+0x58>
f0100fa2:	f6 00 01             	testb  $0x1,(%eax)
f0100fa5:	74 3c                	je     f0100fe3 <page_lookup+0x5f>
  // Stores pte here if it is not NULL
  if(pte_store != NULL)
f0100fa7:	85 db                	test   %ebx,%ebx
f0100fa9:	74 02                	je     f0100fad <page_lookup+0x29>
    *pte_store = pgtable_entry;
f0100fab:	89 03                	mov    %eax,(%ebx)
f0100fad:	8b 00                	mov    (%eax),%eax
f0100faf:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fb2:	39 05 68 79 11 f0    	cmp    %eax,0xf0117968
f0100fb8:	76 0e                	jbe    f0100fc8 <page_lookup+0x44>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0100fba:	8b 15 70 79 11 f0    	mov    0xf0117970,%edx
f0100fc0:	8d 04 c2             	lea    (%edx,%eax,8),%eax
  // Return the PageInfo pointer
  return pa2page(PTE_ADDR(*pgtable_entry)); 
}
f0100fc3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100fc6:	c9                   	leave  
f0100fc7:	c3                   	ret    

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0100fc8:	83 ec 04             	sub    $0x4,%esp
f0100fcb:	68 fc 3e 10 f0       	push   $0xf0103efc
f0100fd0:	6a 4b                	push   $0x4b
f0100fd2:	68 6c 45 10 f0       	push   $0xf010456c
f0100fd7:	e8 af f0 ff ff       	call   f010008b <_panic>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
  pte_t* pgtable_entry = pgdir_walk(pgdir, va, false);
  // Check to see if thie pte is allocated and present
  if(pgtable_entry == NULL || (*pgtable_entry & PTE_P) != 1) return NULL;
f0100fdc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fe1:	eb e0                	jmp    f0100fc3 <page_lookup+0x3f>
f0100fe3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fe8:	eb d9                	jmp    f0100fc3 <page_lookup+0x3f>

f0100fea <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100fea:	55                   	push   %ebp
f0100feb:	89 e5                	mov    %esp,%ebp
f0100fed:	53                   	push   %ebx
f0100fee:	83 ec 18             	sub    $0x18,%esp
f0100ff1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  pte_t *pte_store = NULL;
f0100ff4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  struct PageInfo *page = page_lookup(pgdir, va, &pte_store);
f0100ffb:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ffe:	50                   	push   %eax
f0100fff:	53                   	push   %ebx
f0101000:	ff 75 08             	pushl  0x8(%ebp)
f0101003:	e8 7c ff ff ff       	call   f0100f84 <page_lookup>
  // If page is present
  if(page) {
f0101008:	83 c4 10             	add    $0x10,%esp
f010100b:	85 c0                	test   %eax,%eax
f010100d:	74 18                	je     f0101027 <page_remove+0x3d>
    page_decref(page);
f010100f:	83 ec 0c             	sub    $0xc,%esp
f0101012:	50                   	push   %eax
f0101013:	e8 1d fe ff ff       	call   f0100e35 <page_decref>
    *pte_store = 0;
f0101018:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010101b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101021:	0f 01 3b             	invlpg (%ebx)
f0101024:	83 c4 10             	add    $0x10,%esp
    tlb_invalidate(pgdir, va);
  } 
}
f0101027:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010102a:	c9                   	leave  
f010102b:	c3                   	ret    

f010102c <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010102c:	55                   	push   %ebp
f010102d:	89 e5                	mov    %esp,%ebp
f010102f:	57                   	push   %edi
f0101030:	56                   	push   %esi
f0101031:	53                   	push   %ebx
f0101032:	83 ec 10             	sub    $0x10,%esp
f0101035:	8b 75 08             	mov    0x8(%ebp),%esi
f0101038:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  pte_t* pgtable_entry = pgdir_walk(pgdir, va, true);
f010103b:	6a 01                	push   $0x1
f010103d:	ff 75 10             	pushl  0x10(%ebp)
f0101040:	56                   	push   %esi
f0101041:	e8 15 fe ff ff       	call   f0100e5b <pgdir_walk>
  if(pgtable_entry == NULL) return -E_NO_MEM;
f0101046:	83 c4 10             	add    $0x10,%esp
f0101049:	85 c0                	test   %eax,%eax
f010104b:	74 4b                	je     f0101098 <page_insert+0x6c>
f010104d:	89 c7                	mov    %eax,%edi

  // For corner case
  pp->pp_ref++;
f010104f:	66 ff 43 04          	incw   0x4(%ebx)

  if((*pgtable_entry & PTE_P) == 1) {
f0101053:	f6 00 01             	testb  $0x1,(%eax)
f0101056:	75 2f                	jne    f0101087 <page_insert+0x5b>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101058:	2b 1d 70 79 11 f0    	sub    0xf0117970,%ebx
f010105e:	c1 fb 03             	sar    $0x3,%ebx
f0101061:	c1 e3 0c             	shl    $0xc,%ebx
    page_remove(pgdir, va);
  }

  *pgtable_entry = page2pa(pp) | perm | PTE_P;
f0101064:	8b 45 14             	mov    0x14(%ebp),%eax
f0101067:	83 c8 01             	or     $0x1,%eax
f010106a:	09 c3                	or     %eax,%ebx
f010106c:	89 1f                	mov    %ebx,(%edi)
  pgdir[PDX(va)] |= perm;
f010106e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101071:	c1 e8 16             	shr    $0x16,%eax
f0101074:	8b 55 14             	mov    0x14(%ebp),%edx
f0101077:	09 14 86             	or     %edx,(%esi,%eax,4)

	return 0;
f010107a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010107f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101082:	5b                   	pop    %ebx
f0101083:	5e                   	pop    %esi
f0101084:	5f                   	pop    %edi
f0101085:	5d                   	pop    %ebp
f0101086:	c3                   	ret    

  // For corner case
  pp->pp_ref++;

  if((*pgtable_entry & PTE_P) == 1) {
    page_remove(pgdir, va);
f0101087:	83 ec 08             	sub    $0x8,%esp
f010108a:	ff 75 10             	pushl  0x10(%ebp)
f010108d:	56                   	push   %esi
f010108e:	e8 57 ff ff ff       	call   f0100fea <page_remove>
f0101093:	83 c4 10             	add    $0x10,%esp
f0101096:	eb c0                	jmp    f0101058 <page_insert+0x2c>
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
  pte_t* pgtable_entry = pgdir_walk(pgdir, va, true);
  if(pgtable_entry == NULL) return -E_NO_MEM;
f0101098:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010109d:	eb e0                	jmp    f010107f <page_insert+0x53>

f010109f <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010109f:	55                   	push   %ebp
f01010a0:	89 e5                	mov    %esp,%ebp
f01010a2:	57                   	push   %edi
f01010a3:	56                   	push   %esi
f01010a4:	53                   	push   %ebx
f01010a5:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01010a8:	b8 15 00 00 00       	mov    $0x15,%eax
f01010ad:	e8 16 f8 ff ff       	call   f01008c8 <nvram_read>
f01010b2:	89 c6                	mov    %eax,%esi
	extmem = nvram_read(NVRAM_EXTLO);
f01010b4:	b8 17 00 00 00       	mov    $0x17,%eax
f01010b9:	e8 0a f8 ff ff       	call   f01008c8 <nvram_read>
f01010be:	89 c3                	mov    %eax,%ebx
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01010c0:	b8 34 00 00 00       	mov    $0x34,%eax
f01010c5:	e8 fe f7 ff ff       	call   f01008c8 <nvram_read>

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01010ca:	c1 e0 06             	shl    $0x6,%eax
f01010cd:	75 10                	jne    f01010df <mem_init+0x40>
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
f01010cf:	85 db                	test   %ebx,%ebx
f01010d1:	0f 84 bb 00 00 00    	je     f0101192 <mem_init+0xf3>
		totalmem = 1 * 1024 + extmem;
f01010d7:	8d 83 00 04 00 00    	lea    0x400(%ebx),%eax
f01010dd:	eb 05                	jmp    f01010e4 <mem_init+0x45>
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
f01010df:	05 00 40 00 00       	add    $0x4000,%eax
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01010e4:	89 c2                	mov    %eax,%edx
f01010e6:	c1 ea 02             	shr    $0x2,%edx
f01010e9:	89 15 68 79 11 f0    	mov    %edx,0xf0117968
	npages_basemem = basemem / (PGSIZE / 1024);
f01010ef:	89 f2                	mov    %esi,%edx
f01010f1:	c1 ea 02             	shr    $0x2,%edx
f01010f4:	89 15 40 75 11 f0    	mov    %edx,0xf0117540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01010fa:	89 c2                	mov    %eax,%edx
f01010fc:	29 f2                	sub    %esi,%edx
f01010fe:	52                   	push   %edx
f01010ff:	56                   	push   %esi
f0101100:	50                   	push   %eax
f0101101:	68 1c 3f 10 f0       	push   $0xf0103f1c
f0101106:	e8 e6 17 00 00       	call   f01028f1 <cprintf>
	// Remove this line when you're ready to test this function.
	/* panic("mem_init: This function is not finished\n"); */

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f010110b:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101110:	e8 da f7 ff ff       	call   f01008ef <boot_alloc>
f0101115:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(kern_pgdir, 0, PGSIZE);
f010111a:	83 c4 0c             	add    $0xc,%esp
f010111d:	68 00 10 00 00       	push   $0x1000
f0101122:	6a 00                	push   $0x0
f0101124:	50                   	push   %eax
f0101125:	e8 0f 23 00 00       	call   f0103439 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010112a:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010112f:	83 c4 10             	add    $0x10,%esp
f0101132:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101137:	76 60                	jbe    f0101199 <mem_init+0xfa>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0101139:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010113f:	83 ca 05             	or     $0x5,%edx
f0101142:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
  size_t size = sizeof(struct PageInfo) * npages;
f0101148:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010114d:	c1 e0 03             	shl    $0x3,%eax
f0101150:	89 c7                	mov    %eax,%edi
f0101152:	89 45 c8             	mov    %eax,-0x38(%ebp)
  pages = (struct PageInfo*)boot_alloc(size);
f0101155:	e8 95 f7 ff ff       	call   f01008ef <boot_alloc>
f010115a:	a3 70 79 11 f0       	mov    %eax,0xf0117970
  memset(pages, 0, size);
f010115f:	83 ec 04             	sub    $0x4,%esp
f0101162:	57                   	push   %edi
f0101163:	6a 00                	push   $0x0
f0101165:	50                   	push   %eax
f0101166:	e8 ce 22 00 00       	call   f0103439 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010116b:	e8 2f fb ff ff       	call   f0100c9f <page_init>

	check_page_free_list(1);
f0101170:	b8 01 00 00 00       	mov    $0x1,%eax
f0101175:	e8 5e f8 ff ff       	call   f01009d8 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010117a:	83 c4 10             	add    $0x10,%esp
f010117d:	83 3d 70 79 11 f0 00 	cmpl   $0x0,0xf0117970
f0101184:	74 28                	je     f01011ae <mem_init+0x10f>
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101186:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f010118b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101190:	eb 36                	jmp    f01011c8 <mem_init+0x129>
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
	else
		totalmem = basemem;
f0101192:	89 f0                	mov    %esi,%eax
f0101194:	e9 4b ff ff ff       	jmp    f01010e4 <mem_init+0x45>

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101199:	50                   	push   %eax
f010119a:	68 b0 3e 10 f0       	push   $0xf0103eb0
f010119f:	68 9a 00 00 00       	push   $0x9a
f01011a4:	68 44 45 10 f0       	push   $0xf0104544
f01011a9:	e8 dd ee ff ff       	call   f010008b <_panic>
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
		panic("'pages' is a null pointer!");
f01011ae:	83 ec 04             	sub    $0x4,%esp
f01011b1:	68 16 46 10 f0       	push   $0xf0104616
f01011b6:	68 63 02 00 00       	push   $0x263
f01011bb:	68 44 45 10 f0       	push   $0xf0104544
f01011c0:	e8 c6 ee ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
		++nfree;
f01011c5:	43                   	inc    %ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01011c6:	8b 00                	mov    (%eax),%eax
f01011c8:	85 c0                	test   %eax,%eax
f01011ca:	75 f9                	jne    f01011c5 <mem_init+0x126>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01011cc:	83 ec 0c             	sub    $0xc,%esp
f01011cf:	6a 00                	push   $0x0
f01011d1:	e8 b2 fb ff ff       	call   f0100d88 <page_alloc>
f01011d6:	89 c7                	mov    %eax,%edi
f01011d8:	83 c4 10             	add    $0x10,%esp
f01011db:	85 c0                	test   %eax,%eax
f01011dd:	0f 84 10 02 00 00    	je     f01013f3 <mem_init+0x354>
	assert((pp1 = page_alloc(0)));
f01011e3:	83 ec 0c             	sub    $0xc,%esp
f01011e6:	6a 00                	push   $0x0
f01011e8:	e8 9b fb ff ff       	call   f0100d88 <page_alloc>
f01011ed:	89 c6                	mov    %eax,%esi
f01011ef:	83 c4 10             	add    $0x10,%esp
f01011f2:	85 c0                	test   %eax,%eax
f01011f4:	0f 84 12 02 00 00    	je     f010140c <mem_init+0x36d>
	assert((pp2 = page_alloc(0)));
f01011fa:	83 ec 0c             	sub    $0xc,%esp
f01011fd:	6a 00                	push   $0x0
f01011ff:	e8 84 fb ff ff       	call   f0100d88 <page_alloc>
f0101204:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101207:	83 c4 10             	add    $0x10,%esp
f010120a:	85 c0                	test   %eax,%eax
f010120c:	0f 84 13 02 00 00    	je     f0101425 <mem_init+0x386>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101212:	39 f7                	cmp    %esi,%edi
f0101214:	0f 84 24 02 00 00    	je     f010143e <mem_init+0x39f>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010121a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010121d:	39 c6                	cmp    %eax,%esi
f010121f:	0f 84 32 02 00 00    	je     f0101457 <mem_init+0x3b8>
f0101225:	39 c7                	cmp    %eax,%edi
f0101227:	0f 84 2a 02 00 00    	je     f0101457 <mem_init+0x3b8>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010122d:	8b 0d 70 79 11 f0    	mov    0xf0117970,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101233:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101239:	c1 e2 0c             	shl    $0xc,%edx
f010123c:	89 f8                	mov    %edi,%eax
f010123e:	29 c8                	sub    %ecx,%eax
f0101240:	c1 f8 03             	sar    $0x3,%eax
f0101243:	c1 e0 0c             	shl    $0xc,%eax
f0101246:	39 d0                	cmp    %edx,%eax
f0101248:	0f 83 22 02 00 00    	jae    f0101470 <mem_init+0x3d1>
f010124e:	89 f0                	mov    %esi,%eax
f0101250:	29 c8                	sub    %ecx,%eax
f0101252:	c1 f8 03             	sar    $0x3,%eax
f0101255:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101258:	39 c2                	cmp    %eax,%edx
f010125a:	0f 86 29 02 00 00    	jbe    f0101489 <mem_init+0x3ea>
f0101260:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101263:	29 c8                	sub    %ecx,%eax
f0101265:	c1 f8 03             	sar    $0x3,%eax
f0101268:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010126b:	39 c2                	cmp    %eax,%edx
f010126d:	0f 86 2f 02 00 00    	jbe    f01014a2 <mem_init+0x403>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101273:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101278:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010127b:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101282:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101285:	83 ec 0c             	sub    $0xc,%esp
f0101288:	6a 00                	push   $0x0
f010128a:	e8 f9 fa ff ff       	call   f0100d88 <page_alloc>
f010128f:	83 c4 10             	add    $0x10,%esp
f0101292:	85 c0                	test   %eax,%eax
f0101294:	0f 85 21 02 00 00    	jne    f01014bb <mem_init+0x41c>

	// free and re-allocate?
	page_free(pp0);
f010129a:	83 ec 0c             	sub    $0xc,%esp
f010129d:	57                   	push   %edi
f010129e:	e8 57 fb ff ff       	call   f0100dfa <page_free>
	page_free(pp1);
f01012a3:	89 34 24             	mov    %esi,(%esp)
f01012a6:	e8 4f fb ff ff       	call   f0100dfa <page_free>
	page_free(pp2);
f01012ab:	83 c4 04             	add    $0x4,%esp
f01012ae:	ff 75 d4             	pushl  -0x2c(%ebp)
f01012b1:	e8 44 fb ff ff       	call   f0100dfa <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012b6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012bd:	e8 c6 fa ff ff       	call   f0100d88 <page_alloc>
f01012c2:	89 c6                	mov    %eax,%esi
f01012c4:	83 c4 10             	add    $0x10,%esp
f01012c7:	85 c0                	test   %eax,%eax
f01012c9:	0f 84 05 02 00 00    	je     f01014d4 <mem_init+0x435>
	assert((pp1 = page_alloc(0)));
f01012cf:	83 ec 0c             	sub    $0xc,%esp
f01012d2:	6a 00                	push   $0x0
f01012d4:	e8 af fa ff ff       	call   f0100d88 <page_alloc>
f01012d9:	89 c7                	mov    %eax,%edi
f01012db:	83 c4 10             	add    $0x10,%esp
f01012de:	85 c0                	test   %eax,%eax
f01012e0:	0f 84 07 02 00 00    	je     f01014ed <mem_init+0x44e>
	assert((pp2 = page_alloc(0)));
f01012e6:	83 ec 0c             	sub    $0xc,%esp
f01012e9:	6a 00                	push   $0x0
f01012eb:	e8 98 fa ff ff       	call   f0100d88 <page_alloc>
f01012f0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012f3:	83 c4 10             	add    $0x10,%esp
f01012f6:	85 c0                	test   %eax,%eax
f01012f8:	0f 84 08 02 00 00    	je     f0101506 <mem_init+0x467>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01012fe:	39 fe                	cmp    %edi,%esi
f0101300:	0f 84 19 02 00 00    	je     f010151f <mem_init+0x480>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101306:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101309:	39 c7                	cmp    %eax,%edi
f010130b:	0f 84 27 02 00 00    	je     f0101538 <mem_init+0x499>
f0101311:	39 c6                	cmp    %eax,%esi
f0101313:	0f 84 1f 02 00 00    	je     f0101538 <mem_init+0x499>
	assert(!page_alloc(0));
f0101319:	83 ec 0c             	sub    $0xc,%esp
f010131c:	6a 00                	push   $0x0
f010131e:	e8 65 fa ff ff       	call   f0100d88 <page_alloc>
f0101323:	83 c4 10             	add    $0x10,%esp
f0101326:	85 c0                	test   %eax,%eax
f0101328:	0f 85 23 02 00 00    	jne    f0101551 <mem_init+0x4b2>
f010132e:	89 f0                	mov    %esi,%eax
f0101330:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101336:	c1 f8 03             	sar    $0x3,%eax
f0101339:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010133c:	89 c2                	mov    %eax,%edx
f010133e:	c1 ea 0c             	shr    $0xc,%edx
f0101341:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0101347:	0f 83 1d 02 00 00    	jae    f010156a <mem_init+0x4cb>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010134d:	83 ec 04             	sub    $0x4,%esp
f0101350:	68 00 10 00 00       	push   $0x1000
f0101355:	6a 01                	push   $0x1
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0101357:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010135c:	50                   	push   %eax
f010135d:	e8 d7 20 00 00       	call   f0103439 <memset>
	page_free(pp0);
f0101362:	89 34 24             	mov    %esi,(%esp)
f0101365:	e8 90 fa ff ff       	call   f0100dfa <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010136a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101371:	e8 12 fa ff ff       	call   f0100d88 <page_alloc>
f0101376:	83 c4 10             	add    $0x10,%esp
f0101379:	85 c0                	test   %eax,%eax
f010137b:	0f 84 fb 01 00 00    	je     f010157c <mem_init+0x4dd>
	assert(pp && pp0 == pp);
f0101381:	39 c6                	cmp    %eax,%esi
f0101383:	0f 85 0c 02 00 00    	jne    f0101595 <mem_init+0x4f6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101389:	89 f0                	mov    %esi,%eax
f010138b:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101391:	c1 f8 03             	sar    $0x3,%eax
f0101394:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101397:	89 c2                	mov    %eax,%edx
f0101399:	c1 ea 0c             	shr    $0xc,%edx
f010139c:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f01013a2:	0f 83 06 02 00 00    	jae    f01015ae <mem_init+0x50f>
f01013a8:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f01013ae:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01013b4:	80 38 00             	cmpb   $0x0,(%eax)
f01013b7:	0f 85 03 02 00 00    	jne    f01015c0 <mem_init+0x521>
f01013bd:	40                   	inc    %eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01013be:	39 d0                	cmp    %edx,%eax
f01013c0:	75 f2                	jne    f01013b4 <mem_init+0x315>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01013c2:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01013c5:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01013ca:	83 ec 0c             	sub    $0xc,%esp
f01013cd:	56                   	push   %esi
f01013ce:	e8 27 fa ff ff       	call   f0100dfa <page_free>
	page_free(pp1);
f01013d3:	89 3c 24             	mov    %edi,(%esp)
f01013d6:	e8 1f fa ff ff       	call   f0100dfa <page_free>
	page_free(pp2);
f01013db:	83 c4 04             	add    $0x4,%esp
f01013de:	ff 75 d4             	pushl  -0x2c(%ebp)
f01013e1:	e8 14 fa ff ff       	call   f0100dfa <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01013e6:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01013eb:	83 c4 10             	add    $0x10,%esp
f01013ee:	e9 e9 01 00 00       	jmp    f01015dc <mem_init+0x53d>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01013f3:	68 31 46 10 f0       	push   $0xf0104631
f01013f8:	68 86 45 10 f0       	push   $0xf0104586
f01013fd:	68 6b 02 00 00       	push   $0x26b
f0101402:	68 44 45 10 f0       	push   $0xf0104544
f0101407:	e8 7f ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010140c:	68 47 46 10 f0       	push   $0xf0104647
f0101411:	68 86 45 10 f0       	push   $0xf0104586
f0101416:	68 6c 02 00 00       	push   $0x26c
f010141b:	68 44 45 10 f0       	push   $0xf0104544
f0101420:	e8 66 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101425:	68 5d 46 10 f0       	push   $0xf010465d
f010142a:	68 86 45 10 f0       	push   $0xf0104586
f010142f:	68 6d 02 00 00       	push   $0x26d
f0101434:	68 44 45 10 f0       	push   $0xf0104544
f0101439:	e8 4d ec ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010143e:	68 73 46 10 f0       	push   $0xf0104673
f0101443:	68 86 45 10 f0       	push   $0xf0104586
f0101448:	68 70 02 00 00       	push   $0x270
f010144d:	68 44 45 10 f0       	push   $0xf0104544
f0101452:	e8 34 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101457:	68 58 3f 10 f0       	push   $0xf0103f58
f010145c:	68 86 45 10 f0       	push   $0xf0104586
f0101461:	68 71 02 00 00       	push   $0x271
f0101466:	68 44 45 10 f0       	push   $0xf0104544
f010146b:	e8 1b ec ff ff       	call   f010008b <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101470:	68 85 46 10 f0       	push   $0xf0104685
f0101475:	68 86 45 10 f0       	push   $0xf0104586
f010147a:	68 72 02 00 00       	push   $0x272
f010147f:	68 44 45 10 f0       	push   $0xf0104544
f0101484:	e8 02 ec ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101489:	68 a2 46 10 f0       	push   $0xf01046a2
f010148e:	68 86 45 10 f0       	push   $0xf0104586
f0101493:	68 73 02 00 00       	push   $0x273
f0101498:	68 44 45 10 f0       	push   $0xf0104544
f010149d:	e8 e9 eb ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01014a2:	68 bf 46 10 f0       	push   $0xf01046bf
f01014a7:	68 86 45 10 f0       	push   $0xf0104586
f01014ac:	68 74 02 00 00       	push   $0x274
f01014b1:	68 44 45 10 f0       	push   $0xf0104544
f01014b6:	e8 d0 eb ff ff       	call   f010008b <_panic>
	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;

	// should be no free memory
	assert(!page_alloc(0));
f01014bb:	68 dc 46 10 f0       	push   $0xf01046dc
f01014c0:	68 86 45 10 f0       	push   $0xf0104586
f01014c5:	68 7b 02 00 00       	push   $0x27b
f01014ca:	68 44 45 10 f0       	push   $0xf0104544
f01014cf:	e8 b7 eb ff ff       	call   f010008b <_panic>
	// free and re-allocate?
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014d4:	68 31 46 10 f0       	push   $0xf0104631
f01014d9:	68 86 45 10 f0       	push   $0xf0104586
f01014de:	68 82 02 00 00       	push   $0x282
f01014e3:	68 44 45 10 f0       	push   $0xf0104544
f01014e8:	e8 9e eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01014ed:	68 47 46 10 f0       	push   $0xf0104647
f01014f2:	68 86 45 10 f0       	push   $0xf0104586
f01014f7:	68 83 02 00 00       	push   $0x283
f01014fc:	68 44 45 10 f0       	push   $0xf0104544
f0101501:	e8 85 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101506:	68 5d 46 10 f0       	push   $0xf010465d
f010150b:	68 86 45 10 f0       	push   $0xf0104586
f0101510:	68 84 02 00 00       	push   $0x284
f0101515:	68 44 45 10 f0       	push   $0xf0104544
f010151a:	e8 6c eb ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010151f:	68 73 46 10 f0       	push   $0xf0104673
f0101524:	68 86 45 10 f0       	push   $0xf0104586
f0101529:	68 86 02 00 00       	push   $0x286
f010152e:	68 44 45 10 f0       	push   $0xf0104544
f0101533:	e8 53 eb ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101538:	68 58 3f 10 f0       	push   $0xf0103f58
f010153d:	68 86 45 10 f0       	push   $0xf0104586
f0101542:	68 87 02 00 00       	push   $0x287
f0101547:	68 44 45 10 f0       	push   $0xf0104544
f010154c:	e8 3a eb ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f0101551:	68 dc 46 10 f0       	push   $0xf01046dc
f0101556:	68 86 45 10 f0       	push   $0xf0104586
f010155b:	68 88 02 00 00       	push   $0x288
f0101560:	68 44 45 10 f0       	push   $0xf0104544
f0101565:	e8 21 eb ff ff       	call   f010008b <_panic>

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010156a:	50                   	push   %eax
f010156b:	68 a4 3d 10 f0       	push   $0xf0103da4
f0101570:	6a 52                	push   $0x52
f0101572:	68 6c 45 10 f0       	push   $0xf010456c
f0101577:	e8 0f eb ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
f010157c:	68 eb 46 10 f0       	push   $0xf01046eb
f0101581:	68 86 45 10 f0       	push   $0xf0104586
f0101586:	68 8d 02 00 00       	push   $0x28d
f010158b:	68 44 45 10 f0       	push   $0xf0104544
f0101590:	e8 f6 ea ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101595:	68 09 47 10 f0       	push   $0xf0104709
f010159a:	68 86 45 10 f0       	push   $0xf0104586
f010159f:	68 8e 02 00 00       	push   $0x28e
f01015a4:	68 44 45 10 f0       	push   $0xf0104544
f01015a9:	e8 dd ea ff ff       	call   f010008b <_panic>
f01015ae:	50                   	push   %eax
f01015af:	68 a4 3d 10 f0       	push   $0xf0103da4
f01015b4:	6a 52                	push   $0x52
f01015b6:	68 6c 45 10 f0       	push   $0xf010456c
f01015bb:	e8 cb ea ff ff       	call   f010008b <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01015c0:	68 19 47 10 f0       	push   $0xf0104719
f01015c5:	68 86 45 10 f0       	push   $0xf0104586
f01015ca:	68 91 02 00 00       	push   $0x291
f01015cf:	68 44 45 10 f0       	push   $0xf0104544
f01015d4:	e8 b2 ea ff ff       	call   f010008b <_panic>
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
		--nfree;
f01015d9:	4b                   	dec    %ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015da:	8b 00                	mov    (%eax),%eax
f01015dc:	85 c0                	test   %eax,%eax
f01015de:	75 f9                	jne    f01015d9 <mem_init+0x53a>
		--nfree;
	assert(nfree == 0);
f01015e0:	85 db                	test   %ebx,%ebx
f01015e2:	0f 85 89 07 00 00    	jne    f0101d71 <mem_init+0xcd2>

	cprintf("check_page_alloc() succeeded!\n");
f01015e8:	83 ec 0c             	sub    $0xc,%esp
f01015eb:	68 78 3f 10 f0       	push   $0xf0103f78
f01015f0:	e8 fc 12 00 00       	call   f01028f1 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015f5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015fc:	e8 87 f7 ff ff       	call   f0100d88 <page_alloc>
f0101601:	89 c7                	mov    %eax,%edi
f0101603:	83 c4 10             	add    $0x10,%esp
f0101606:	85 c0                	test   %eax,%eax
f0101608:	0f 84 7c 07 00 00    	je     f0101d8a <mem_init+0xceb>
	assert((pp1 = page_alloc(0)));
f010160e:	83 ec 0c             	sub    $0xc,%esp
f0101611:	6a 00                	push   $0x0
f0101613:	e8 70 f7 ff ff       	call   f0100d88 <page_alloc>
f0101618:	89 c3                	mov    %eax,%ebx
f010161a:	83 c4 10             	add    $0x10,%esp
f010161d:	85 c0                	test   %eax,%eax
f010161f:	0f 84 7e 07 00 00    	je     f0101da3 <mem_init+0xd04>
	assert((pp2 = page_alloc(0)));
f0101625:	83 ec 0c             	sub    $0xc,%esp
f0101628:	6a 00                	push   $0x0
f010162a:	e8 59 f7 ff ff       	call   f0100d88 <page_alloc>
f010162f:	89 c6                	mov    %eax,%esi
f0101631:	83 c4 10             	add    $0x10,%esp
f0101634:	85 c0                	test   %eax,%eax
f0101636:	0f 84 80 07 00 00    	je     f0101dbc <mem_init+0xd1d>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010163c:	39 df                	cmp    %ebx,%edi
f010163e:	0f 84 91 07 00 00    	je     f0101dd5 <mem_init+0xd36>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101644:	39 c3                	cmp    %eax,%ebx
f0101646:	0f 84 a2 07 00 00    	je     f0101dee <mem_init+0xd4f>
f010164c:	39 c7                	cmp    %eax,%edi
f010164e:	0f 84 9a 07 00 00    	je     f0101dee <mem_init+0xd4f>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101654:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101659:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	page_free_list = 0;
f010165c:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f0101663:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101666:	83 ec 0c             	sub    $0xc,%esp
f0101669:	6a 00                	push   $0x0
f010166b:	e8 18 f7 ff ff       	call   f0100d88 <page_alloc>
f0101670:	83 c4 10             	add    $0x10,%esp
f0101673:	85 c0                	test   %eax,%eax
f0101675:	0f 85 8c 07 00 00    	jne    f0101e07 <mem_init+0xd68>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010167b:	83 ec 04             	sub    $0x4,%esp
f010167e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101681:	50                   	push   %eax
f0101682:	6a 00                	push   $0x0
f0101684:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f010168a:	e8 f5 f8 ff ff       	call   f0100f84 <page_lookup>
f010168f:	83 c4 10             	add    $0x10,%esp
f0101692:	85 c0                	test   %eax,%eax
f0101694:	0f 85 86 07 00 00    	jne    f0101e20 <mem_init+0xd81>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010169a:	6a 02                	push   $0x2
f010169c:	6a 00                	push   $0x0
f010169e:	53                   	push   %ebx
f010169f:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f01016a5:	e8 82 f9 ff ff       	call   f010102c <page_insert>
f01016aa:	83 c4 10             	add    $0x10,%esp
f01016ad:	85 c0                	test   %eax,%eax
f01016af:	0f 89 84 07 00 00    	jns    f0101e39 <mem_init+0xd9a>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01016b5:	83 ec 0c             	sub    $0xc,%esp
f01016b8:	57                   	push   %edi
f01016b9:	e8 3c f7 ff ff       	call   f0100dfa <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01016be:	6a 02                	push   $0x2
f01016c0:	6a 00                	push   $0x0
f01016c2:	53                   	push   %ebx
f01016c3:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f01016c9:	e8 5e f9 ff ff       	call   f010102c <page_insert>
f01016ce:	83 c4 20             	add    $0x20,%esp
f01016d1:	85 c0                	test   %eax,%eax
f01016d3:	0f 85 79 07 00 00    	jne    f0101e52 <mem_init+0xdb3>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016d9:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01016de:	89 45 d4             	mov    %eax,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016e1:	8b 0d 70 79 11 f0    	mov    0xf0117970,%ecx
f01016e7:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01016ea:	8b 00                	mov    (%eax),%eax
f01016ec:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016ef:	89 c2                	mov    %eax,%edx
f01016f1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01016f7:	89 f8                	mov    %edi,%eax
f01016f9:	29 c8                	sub    %ecx,%eax
f01016fb:	c1 f8 03             	sar    $0x3,%eax
f01016fe:	c1 e0 0c             	shl    $0xc,%eax
f0101701:	39 c2                	cmp    %eax,%edx
f0101703:	0f 85 62 07 00 00    	jne    f0101e6b <mem_init+0xdcc>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101709:	ba 00 00 00 00       	mov    $0x0,%edx
f010170e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101711:	e8 61 f2 ff ff       	call   f0100977 <check_va2pa>
f0101716:	89 da                	mov    %ebx,%edx
f0101718:	2b 55 d0             	sub    -0x30(%ebp),%edx
f010171b:	c1 fa 03             	sar    $0x3,%edx
f010171e:	c1 e2 0c             	shl    $0xc,%edx
f0101721:	39 d0                	cmp    %edx,%eax
f0101723:	0f 85 5b 07 00 00    	jne    f0101e84 <mem_init+0xde5>
	assert(pp1->pp_ref == 1);
f0101729:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010172e:	0f 85 69 07 00 00    	jne    f0101e9d <mem_init+0xdfe>
	assert(pp0->pp_ref == 1);
f0101734:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101739:	0f 85 77 07 00 00    	jne    f0101eb6 <mem_init+0xe17>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010173f:	6a 02                	push   $0x2
f0101741:	68 00 10 00 00       	push   $0x1000
f0101746:	56                   	push   %esi
f0101747:	ff 75 d4             	pushl  -0x2c(%ebp)
f010174a:	e8 dd f8 ff ff       	call   f010102c <page_insert>
f010174f:	83 c4 10             	add    $0x10,%esp
f0101752:	85 c0                	test   %eax,%eax
f0101754:	0f 85 75 07 00 00    	jne    f0101ecf <mem_init+0xe30>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010175a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010175f:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101764:	e8 0e f2 ff ff       	call   f0100977 <check_va2pa>
f0101769:	89 f2                	mov    %esi,%edx
f010176b:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101771:	c1 fa 03             	sar    $0x3,%edx
f0101774:	c1 e2 0c             	shl    $0xc,%edx
f0101777:	39 d0                	cmp    %edx,%eax
f0101779:	0f 85 69 07 00 00    	jne    f0101ee8 <mem_init+0xe49>
	assert(pp2->pp_ref == 1);
f010177f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101784:	0f 85 77 07 00 00    	jne    f0101f01 <mem_init+0xe62>

	// should be no free memory
	assert(!page_alloc(0));
f010178a:	83 ec 0c             	sub    $0xc,%esp
f010178d:	6a 00                	push   $0x0
f010178f:	e8 f4 f5 ff ff       	call   f0100d88 <page_alloc>
f0101794:	83 c4 10             	add    $0x10,%esp
f0101797:	85 c0                	test   %eax,%eax
f0101799:	0f 85 7b 07 00 00    	jne    f0101f1a <mem_init+0xe7b>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010179f:	6a 02                	push   $0x2
f01017a1:	68 00 10 00 00       	push   $0x1000
f01017a6:	56                   	push   %esi
f01017a7:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f01017ad:	e8 7a f8 ff ff       	call   f010102c <page_insert>
f01017b2:	83 c4 10             	add    $0x10,%esp
f01017b5:	85 c0                	test   %eax,%eax
f01017b7:	0f 85 76 07 00 00    	jne    f0101f33 <mem_init+0xe94>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017bd:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017c2:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01017c7:	e8 ab f1 ff ff       	call   f0100977 <check_va2pa>
f01017cc:	89 f2                	mov    %esi,%edx
f01017ce:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f01017d4:	c1 fa 03             	sar    $0x3,%edx
f01017d7:	c1 e2 0c             	shl    $0xc,%edx
f01017da:	39 d0                	cmp    %edx,%eax
f01017dc:	0f 85 6a 07 00 00    	jne    f0101f4c <mem_init+0xead>
	assert(pp2->pp_ref == 1);
f01017e2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017e7:	0f 85 78 07 00 00    	jne    f0101f65 <mem_init+0xec6>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01017ed:	83 ec 0c             	sub    $0xc,%esp
f01017f0:	6a 00                	push   $0x0
f01017f2:	e8 91 f5 ff ff       	call   f0100d88 <page_alloc>
f01017f7:	83 c4 10             	add    $0x10,%esp
f01017fa:	85 c0                	test   %eax,%eax
f01017fc:	0f 85 7c 07 00 00    	jne    f0101f7e <mem_init+0xedf>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101802:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0101808:	8b 02                	mov    (%edx),%eax
f010180a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010180f:	89 c1                	mov    %eax,%ecx
f0101811:	c1 e9 0c             	shr    $0xc,%ecx
f0101814:	3b 0d 68 79 11 f0    	cmp    0xf0117968,%ecx
f010181a:	0f 83 77 07 00 00    	jae    f0101f97 <mem_init+0xef8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0101820:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101825:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101828:	83 ec 04             	sub    $0x4,%esp
f010182b:	6a 00                	push   $0x0
f010182d:	68 00 10 00 00       	push   $0x1000
f0101832:	52                   	push   %edx
f0101833:	e8 23 f6 ff ff       	call   f0100e5b <pgdir_walk>
f0101838:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010183b:	8d 51 04             	lea    0x4(%ecx),%edx
f010183e:	83 c4 10             	add    $0x10,%esp
f0101841:	39 d0                	cmp    %edx,%eax
f0101843:	0f 85 63 07 00 00    	jne    f0101fac <mem_init+0xf0d>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101849:	6a 06                	push   $0x6
f010184b:	68 00 10 00 00       	push   $0x1000
f0101850:	56                   	push   %esi
f0101851:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101857:	e8 d0 f7 ff ff       	call   f010102c <page_insert>
f010185c:	83 c4 10             	add    $0x10,%esp
f010185f:	85 c0                	test   %eax,%eax
f0101861:	0f 85 5e 07 00 00    	jne    f0101fc5 <mem_init+0xf26>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101867:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010186c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010186f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101874:	e8 fe f0 ff ff       	call   f0100977 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101879:	89 f2                	mov    %esi,%edx
f010187b:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101881:	c1 fa 03             	sar    $0x3,%edx
f0101884:	c1 e2 0c             	shl    $0xc,%edx
f0101887:	39 d0                	cmp    %edx,%eax
f0101889:	0f 85 4f 07 00 00    	jne    f0101fde <mem_init+0xf3f>
	assert(pp2->pp_ref == 1);
f010188f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101894:	0f 85 5d 07 00 00    	jne    f0101ff7 <mem_init+0xf58>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010189a:	83 ec 04             	sub    $0x4,%esp
f010189d:	6a 00                	push   $0x0
f010189f:	68 00 10 00 00       	push   $0x1000
f01018a4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01018a7:	e8 af f5 ff ff       	call   f0100e5b <pgdir_walk>
f01018ac:	83 c4 10             	add    $0x10,%esp
f01018af:	f6 00 04             	testb  $0x4,(%eax)
f01018b2:	0f 84 58 07 00 00    	je     f0102010 <mem_init+0xf71>
	assert(kern_pgdir[0] & PTE_U);
f01018b8:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01018bd:	f6 00 04             	testb  $0x4,(%eax)
f01018c0:	0f 84 63 07 00 00    	je     f0102029 <mem_init+0xf8a>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01018c6:	6a 02                	push   $0x2
f01018c8:	68 00 10 00 00       	push   $0x1000
f01018cd:	56                   	push   %esi
f01018ce:	50                   	push   %eax
f01018cf:	e8 58 f7 ff ff       	call   f010102c <page_insert>
f01018d4:	83 c4 10             	add    $0x10,%esp
f01018d7:	85 c0                	test   %eax,%eax
f01018d9:	0f 85 63 07 00 00    	jne    f0102042 <mem_init+0xfa3>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01018df:	83 ec 04             	sub    $0x4,%esp
f01018e2:	6a 00                	push   $0x0
f01018e4:	68 00 10 00 00       	push   $0x1000
f01018e9:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f01018ef:	e8 67 f5 ff ff       	call   f0100e5b <pgdir_walk>
f01018f4:	83 c4 10             	add    $0x10,%esp
f01018f7:	f6 00 02             	testb  $0x2,(%eax)
f01018fa:	0f 84 5b 07 00 00    	je     f010205b <mem_init+0xfbc>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101900:	83 ec 04             	sub    $0x4,%esp
f0101903:	6a 00                	push   $0x0
f0101905:	68 00 10 00 00       	push   $0x1000
f010190a:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101910:	e8 46 f5 ff ff       	call   f0100e5b <pgdir_walk>
f0101915:	83 c4 10             	add    $0x10,%esp
f0101918:	f6 00 04             	testb  $0x4,(%eax)
f010191b:	0f 85 53 07 00 00    	jne    f0102074 <mem_init+0xfd5>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101921:	6a 02                	push   $0x2
f0101923:	68 00 00 40 00       	push   $0x400000
f0101928:	57                   	push   %edi
f0101929:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f010192f:	e8 f8 f6 ff ff       	call   f010102c <page_insert>
f0101934:	83 c4 10             	add    $0x10,%esp
f0101937:	85 c0                	test   %eax,%eax
f0101939:	0f 89 4e 07 00 00    	jns    f010208d <mem_init+0xfee>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010193f:	6a 02                	push   $0x2
f0101941:	68 00 10 00 00       	push   $0x1000
f0101946:	53                   	push   %ebx
f0101947:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f010194d:	e8 da f6 ff ff       	call   f010102c <page_insert>
f0101952:	83 c4 10             	add    $0x10,%esp
f0101955:	85 c0                	test   %eax,%eax
f0101957:	0f 85 49 07 00 00    	jne    f01020a6 <mem_init+0x1007>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010195d:	83 ec 04             	sub    $0x4,%esp
f0101960:	6a 00                	push   $0x0
f0101962:	68 00 10 00 00       	push   $0x1000
f0101967:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f010196d:	e8 e9 f4 ff ff       	call   f0100e5b <pgdir_walk>
f0101972:	83 c4 10             	add    $0x10,%esp
f0101975:	f6 00 04             	testb  $0x4,(%eax)
f0101978:	0f 85 41 07 00 00    	jne    f01020bf <mem_init+0x1020>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010197e:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101983:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101986:	ba 00 00 00 00       	mov    $0x0,%edx
f010198b:	e8 e7 ef ff ff       	call   f0100977 <check_va2pa>
f0101990:	89 c1                	mov    %eax,%ecx
f0101992:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101995:	89 d8                	mov    %ebx,%eax
f0101997:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f010199d:	c1 f8 03             	sar    $0x3,%eax
f01019a0:	c1 e0 0c             	shl    $0xc,%eax
f01019a3:	39 c1                	cmp    %eax,%ecx
f01019a5:	0f 85 2d 07 00 00    	jne    f01020d8 <mem_init+0x1039>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01019ab:	ba 00 10 00 00       	mov    $0x1000,%edx
f01019b0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019b3:	e8 bf ef ff ff       	call   f0100977 <check_va2pa>
f01019b8:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01019bb:	0f 85 30 07 00 00    	jne    f01020f1 <mem_init+0x1052>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01019c1:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01019c6:	0f 85 3e 07 00 00    	jne    f010210a <mem_init+0x106b>
	assert(pp2->pp_ref == 0);
f01019cc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01019d1:	0f 85 4c 07 00 00    	jne    f0102123 <mem_init+0x1084>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01019d7:	83 ec 0c             	sub    $0xc,%esp
f01019da:	6a 00                	push   $0x0
f01019dc:	e8 a7 f3 ff ff       	call   f0100d88 <page_alloc>
f01019e1:	83 c4 10             	add    $0x10,%esp
f01019e4:	85 c0                	test   %eax,%eax
f01019e6:	0f 84 50 07 00 00    	je     f010213c <mem_init+0x109d>
f01019ec:	39 c6                	cmp    %eax,%esi
f01019ee:	0f 85 48 07 00 00    	jne    f010213c <mem_init+0x109d>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01019f4:	83 ec 08             	sub    $0x8,%esp
f01019f7:	6a 00                	push   $0x0
f01019f9:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f01019ff:	e8 e6 f5 ff ff       	call   f0100fea <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101a04:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101a09:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a0c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a11:	e8 61 ef ff ff       	call   f0100977 <check_va2pa>
f0101a16:	83 c4 10             	add    $0x10,%esp
f0101a19:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101a1c:	0f 85 33 07 00 00    	jne    f0102155 <mem_init+0x10b6>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101a22:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a27:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a2a:	e8 48 ef ff ff       	call   f0100977 <check_va2pa>
f0101a2f:	89 da                	mov    %ebx,%edx
f0101a31:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101a37:	c1 fa 03             	sar    $0x3,%edx
f0101a3a:	c1 e2 0c             	shl    $0xc,%edx
f0101a3d:	39 d0                	cmp    %edx,%eax
f0101a3f:	0f 85 29 07 00 00    	jne    f010216e <mem_init+0x10cf>
	assert(pp1->pp_ref == 1);
f0101a45:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a4a:	0f 85 37 07 00 00    	jne    f0102187 <mem_init+0x10e8>
	assert(pp2->pp_ref == 0);
f0101a50:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101a55:	0f 85 45 07 00 00    	jne    f01021a0 <mem_init+0x1101>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101a5b:	6a 00                	push   $0x0
f0101a5d:	68 00 10 00 00       	push   $0x1000
f0101a62:	53                   	push   %ebx
f0101a63:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a66:	e8 c1 f5 ff ff       	call   f010102c <page_insert>
f0101a6b:	83 c4 10             	add    $0x10,%esp
f0101a6e:	85 c0                	test   %eax,%eax
f0101a70:	0f 85 43 07 00 00    	jne    f01021b9 <mem_init+0x111a>
	assert(pp1->pp_ref);
f0101a76:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101a7b:	0f 84 51 07 00 00    	je     f01021d2 <mem_init+0x1133>
	assert(pp1->pp_link == NULL);
f0101a81:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101a84:	0f 85 61 07 00 00    	jne    f01021eb <mem_init+0x114c>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101a8a:	83 ec 08             	sub    $0x8,%esp
f0101a8d:	68 00 10 00 00       	push   $0x1000
f0101a92:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101a98:	e8 4d f5 ff ff       	call   f0100fea <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101a9d:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101aa2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101aa5:	ba 00 00 00 00       	mov    $0x0,%edx
f0101aaa:	e8 c8 ee ff ff       	call   f0100977 <check_va2pa>
f0101aaf:	83 c4 10             	add    $0x10,%esp
f0101ab2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ab5:	0f 85 49 07 00 00    	jne    f0102204 <mem_init+0x1165>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101abb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ac0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac3:	e8 af ee ff ff       	call   f0100977 <check_va2pa>
f0101ac8:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101acb:	0f 85 4c 07 00 00    	jne    f010221d <mem_init+0x117e>
	assert(pp1->pp_ref == 0);
f0101ad1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101ad6:	0f 85 5a 07 00 00    	jne    f0102236 <mem_init+0x1197>
	assert(pp2->pp_ref == 0);
f0101adc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ae1:	0f 85 68 07 00 00    	jne    f010224f <mem_init+0x11b0>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101ae7:	83 ec 0c             	sub    $0xc,%esp
f0101aea:	6a 00                	push   $0x0
f0101aec:	e8 97 f2 ff ff       	call   f0100d88 <page_alloc>
f0101af1:	83 c4 10             	add    $0x10,%esp
f0101af4:	85 c0                	test   %eax,%eax
f0101af6:	0f 84 6c 07 00 00    	je     f0102268 <mem_init+0x11c9>
f0101afc:	39 c3                	cmp    %eax,%ebx
f0101afe:	0f 85 64 07 00 00    	jne    f0102268 <mem_init+0x11c9>

	// should be no free memory
	assert(!page_alloc(0));
f0101b04:	83 ec 0c             	sub    $0xc,%esp
f0101b07:	6a 00                	push   $0x0
f0101b09:	e8 7a f2 ff ff       	call   f0100d88 <page_alloc>
f0101b0e:	83 c4 10             	add    $0x10,%esp
f0101b11:	85 c0                	test   %eax,%eax
f0101b13:	0f 85 68 07 00 00    	jne    f0102281 <mem_init+0x11e2>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b19:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f0101b1f:	8b 11                	mov    (%ecx),%edx
f0101b21:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b27:	89 f8                	mov    %edi,%eax
f0101b29:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101b2f:	c1 f8 03             	sar    $0x3,%eax
f0101b32:	c1 e0 0c             	shl    $0xc,%eax
f0101b35:	39 c2                	cmp    %eax,%edx
f0101b37:	0f 85 5d 07 00 00    	jne    f010229a <mem_init+0x11fb>
	kern_pgdir[0] = 0;
f0101b3d:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101b43:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b48:	0f 85 65 07 00 00    	jne    f01022b3 <mem_init+0x1214>
	pp0->pp_ref = 0;
f0101b4e:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101b54:	83 ec 0c             	sub    $0xc,%esp
f0101b57:	57                   	push   %edi
f0101b58:	e8 9d f2 ff ff       	call   f0100dfa <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101b5d:	83 c4 0c             	add    $0xc,%esp
f0101b60:	6a 01                	push   $0x1
f0101b62:	68 00 10 40 00       	push   $0x401000
f0101b67:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101b6d:	e8 e9 f2 ff ff       	call   f0100e5b <pgdir_walk>
f0101b72:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b75:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101b78:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101b7d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101b80:	8b 50 04             	mov    0x4(%eax),%edx
f0101b83:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b89:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b8e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b91:	89 d1                	mov    %edx,%ecx
f0101b93:	c1 e9 0c             	shr    $0xc,%ecx
f0101b96:	83 c4 10             	add    $0x10,%esp
f0101b99:	39 c1                	cmp    %eax,%ecx
f0101b9b:	0f 83 2b 07 00 00    	jae    f01022cc <mem_init+0x122d>
	assert(ptep == ptep1 + PTX(va));
f0101ba1:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0101ba7:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
f0101baa:	0f 85 31 07 00 00    	jne    f01022e1 <mem_init+0x1242>
	kern_pgdir[PDX(va)] = 0;
f0101bb0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bb3:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101bba:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101bc0:	89 f8                	mov    %edi,%eax
f0101bc2:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0101bc8:	c1 f8 03             	sar    $0x3,%eax
f0101bcb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101bce:	89 c2                	mov    %eax,%edx
f0101bd0:	c1 ea 0c             	shr    $0xc,%edx
f0101bd3:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0101bd6:	0f 86 1e 07 00 00    	jbe    f01022fa <mem_init+0x125b>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101bdc:	83 ec 04             	sub    $0x4,%esp
f0101bdf:	68 00 10 00 00       	push   $0x1000
f0101be4:	68 ff 00 00 00       	push   $0xff
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0101be9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101bee:	50                   	push   %eax
f0101bef:	e8 45 18 00 00       	call   f0103439 <memset>
	page_free(pp0);
f0101bf4:	89 3c 24             	mov    %edi,(%esp)
f0101bf7:	e8 fe f1 ff ff       	call   f0100dfa <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101bfc:	83 c4 0c             	add    $0xc,%esp
f0101bff:	6a 01                	push   $0x1
f0101c01:	6a 00                	push   $0x0
f0101c03:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0101c09:	e8 4d f2 ff ff       	call   f0100e5b <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101c0e:	89 fa                	mov    %edi,%edx
f0101c10:	2b 15 70 79 11 f0    	sub    0xf0117970,%edx
f0101c16:	c1 fa 03             	sar    $0x3,%edx
f0101c19:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c1c:	89 d0                	mov    %edx,%eax
f0101c1e:	c1 e8 0c             	shr    $0xc,%eax
f0101c21:	83 c4 10             	add    $0x10,%esp
f0101c24:	3b 05 68 79 11 f0    	cmp    0xf0117968,%eax
f0101c2a:	0f 83 dc 06 00 00    	jae    f010230c <mem_init+0x126d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f0101c30:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0101c36:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101c39:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0101c3f:	f6 00 01             	testb  $0x1,(%eax)
f0101c42:	0f 85 d6 06 00 00    	jne    f010231e <mem_init+0x127f>
f0101c48:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0101c4b:	39 c2                	cmp    %eax,%edx
f0101c4d:	75 f0                	jne    f0101c3f <mem_init+0xba0>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0101c4f:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101c54:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0101c5a:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// give free list back
	page_free_list = fl;
f0101c60:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0101c63:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f0101c68:	83 ec 0c             	sub    $0xc,%esp
f0101c6b:	57                   	push   %edi
f0101c6c:	e8 89 f1 ff ff       	call   f0100dfa <page_free>
	page_free(pp1);
f0101c71:	89 1c 24             	mov    %ebx,(%esp)
f0101c74:	e8 81 f1 ff ff       	call   f0100dfa <page_free>
	page_free(pp2);
f0101c79:	89 34 24             	mov    %esi,(%esp)
f0101c7c:	e8 79 f1 ff ff       	call   f0100dfa <page_free>

	cprintf("check_page() succeeded!\n");
f0101c81:	c7 04 24 fa 47 10 f0 	movl   $0xf01047fa,(%esp)
f0101c88:	e8 64 0c 00 00       	call   f01028f1 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
  boot_map_region(kern_pgdir, UPAGES, size, PADDR(pages), PTE_U | PTE_P);
f0101c8d:	a1 70 79 11 f0       	mov    0xf0117970,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101c92:	83 c4 10             	add    $0x10,%esp
f0101c95:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101c9a:	0f 86 97 06 00 00    	jbe    f0102337 <mem_init+0x1298>
f0101ca0:	83 ec 08             	sub    $0x8,%esp
f0101ca3:	6a 05                	push   $0x5
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0101ca5:	05 00 00 00 10       	add    $0x10000000,%eax
f0101caa:	50                   	push   %eax
f0101cab:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101cae:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0101cb3:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101cb8:	e8 6e f2 ff ff       	call   f0100f2b <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101cbd:	83 c4 10             	add    $0x10,%esp
f0101cc0:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f0101cc5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101cca:	0f 86 7c 06 00 00    	jbe    f010234c <mem_init+0x12ad>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
  boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), 
f0101cd0:	83 ec 08             	sub    $0x8,%esp
f0101cd3:	6a 03                	push   $0x3
f0101cd5:	68 00 d0 10 00       	push   $0x10d000
f0101cda:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0101cdf:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0101ce4:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101ce9:	e8 3d f2 ff ff       	call   f0100f2b <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
  boot_map_region(kern_pgdir, KERNBASE, ~((uint32_t)0) - KERNBASE, 0, PTE_W | PTE_P); 
f0101cee:	83 c4 08             	add    $0x8,%esp
f0101cf1:	6a 03                	push   $0x3
f0101cf3:	6a 00                	push   $0x0
f0101cf5:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0101cfa:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0101cff:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101d04:	e8 22 f2 ff ff       	call   f0100f2b <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0101d09:	8b 35 6c 79 11 f0    	mov    0xf011796c,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0101d0f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101d14:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101d17:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0101d1e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101d23:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101d26:	8b 3d 70 79 11 f0    	mov    0xf0117970,%edi
f0101d2c:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101d2f:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0101d32:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101d37:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101d3a:	0f 86 4f 06 00 00    	jbe    f010238f <mem_init+0x12f0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101d40:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0101d46:	89 f0                	mov    %esi,%eax
f0101d48:	e8 2a ec ff ff       	call   f0100977 <check_va2pa>
f0101d4d:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0101d54:	0f 86 07 06 00 00    	jbe    f0102361 <mem_init+0x12c2>
f0101d5a:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f0101d61:	39 d0                	cmp    %edx,%eax
f0101d63:	0f 85 0d 06 00 00    	jne    f0102376 <mem_init+0x12d7>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0101d69:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101d6f:	eb c6                	jmp    f0101d37 <mem_init+0xc98>
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
		--nfree;
	assert(nfree == 0);
f0101d71:	68 23 47 10 f0       	push   $0xf0104723
f0101d76:	68 86 45 10 f0       	push   $0xf0104586
f0101d7b:	68 9e 02 00 00       	push   $0x29e
f0101d80:	68 44 45 10 f0       	push   $0xf0104544
f0101d85:	e8 01 e3 ff ff       	call   f010008b <_panic>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101d8a:	68 31 46 10 f0       	push   $0xf0104631
f0101d8f:	68 86 45 10 f0       	push   $0xf0104586
f0101d94:	68 f7 02 00 00       	push   $0x2f7
f0101d99:	68 44 45 10 f0       	push   $0xf0104544
f0101d9e:	e8 e8 e2 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101da3:	68 47 46 10 f0       	push   $0xf0104647
f0101da8:	68 86 45 10 f0       	push   $0xf0104586
f0101dad:	68 f8 02 00 00       	push   $0x2f8
f0101db2:	68 44 45 10 f0       	push   $0xf0104544
f0101db7:	e8 cf e2 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101dbc:	68 5d 46 10 f0       	push   $0xf010465d
f0101dc1:	68 86 45 10 f0       	push   $0xf0104586
f0101dc6:	68 f9 02 00 00       	push   $0x2f9
f0101dcb:	68 44 45 10 f0       	push   $0xf0104544
f0101dd0:	e8 b6 e2 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101dd5:	68 73 46 10 f0       	push   $0xf0104673
f0101dda:	68 86 45 10 f0       	push   $0xf0104586
f0101ddf:	68 fc 02 00 00       	push   $0x2fc
f0101de4:	68 44 45 10 f0       	push   $0xf0104544
f0101de9:	e8 9d e2 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101dee:	68 58 3f 10 f0       	push   $0xf0103f58
f0101df3:	68 86 45 10 f0       	push   $0xf0104586
f0101df8:	68 fd 02 00 00       	push   $0x2fd
f0101dfd:	68 44 45 10 f0       	push   $0xf0104544
f0101e02:	e8 84 e2 ff ff       	call   f010008b <_panic>
	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;

	// should be no free memory
	assert(!page_alloc(0));
f0101e07:	68 dc 46 10 f0       	push   $0xf01046dc
f0101e0c:	68 86 45 10 f0       	push   $0xf0104586
f0101e11:	68 04 03 00 00       	push   $0x304
f0101e16:	68 44 45 10 f0       	push   $0xf0104544
f0101e1b:	e8 6b e2 ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101e20:	68 98 3f 10 f0       	push   $0xf0103f98
f0101e25:	68 86 45 10 f0       	push   $0xf0104586
f0101e2a:	68 07 03 00 00       	push   $0x307
f0101e2f:	68 44 45 10 f0       	push   $0xf0104544
f0101e34:	e8 52 e2 ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101e39:	68 d0 3f 10 f0       	push   $0xf0103fd0
f0101e3e:	68 86 45 10 f0       	push   $0xf0104586
f0101e43:	68 0a 03 00 00       	push   $0x30a
f0101e48:	68 44 45 10 f0       	push   $0xf0104544
f0101e4d:	e8 39 e2 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101e52:	68 00 40 10 f0       	push   $0xf0104000
f0101e57:	68 86 45 10 f0       	push   $0xf0104586
f0101e5c:	68 0e 03 00 00       	push   $0x30e
f0101e61:	68 44 45 10 f0       	push   $0xf0104544
f0101e66:	e8 20 e2 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e6b:	68 30 40 10 f0       	push   $0xf0104030
f0101e70:	68 86 45 10 f0       	push   $0xf0104586
f0101e75:	68 0f 03 00 00       	push   $0x30f
f0101e7a:	68 44 45 10 f0       	push   $0xf0104544
f0101e7f:	e8 07 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101e84:	68 58 40 10 f0       	push   $0xf0104058
f0101e89:	68 86 45 10 f0       	push   $0xf0104586
f0101e8e:	68 10 03 00 00       	push   $0x310
f0101e93:	68 44 45 10 f0       	push   $0xf0104544
f0101e98:	e8 ee e1 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101e9d:	68 2e 47 10 f0       	push   $0xf010472e
f0101ea2:	68 86 45 10 f0       	push   $0xf0104586
f0101ea7:	68 11 03 00 00       	push   $0x311
f0101eac:	68 44 45 10 f0       	push   $0xf0104544
f0101eb1:	e8 d5 e1 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f0101eb6:	68 3f 47 10 f0       	push   $0xf010473f
f0101ebb:	68 86 45 10 f0       	push   $0xf0104586
f0101ec0:	68 12 03 00 00       	push   $0x312
f0101ec5:	68 44 45 10 f0       	push   $0xf0104544
f0101eca:	e8 bc e1 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ecf:	68 88 40 10 f0       	push   $0xf0104088
f0101ed4:	68 86 45 10 f0       	push   $0xf0104586
f0101ed9:	68 15 03 00 00       	push   $0x315
f0101ede:	68 44 45 10 f0       	push   $0xf0104544
f0101ee3:	e8 a3 e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ee8:	68 c4 40 10 f0       	push   $0xf01040c4
f0101eed:	68 86 45 10 f0       	push   $0xf0104586
f0101ef2:	68 16 03 00 00       	push   $0x316
f0101ef7:	68 44 45 10 f0       	push   $0xf0104544
f0101efc:	e8 8a e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101f01:	68 50 47 10 f0       	push   $0xf0104750
f0101f06:	68 86 45 10 f0       	push   $0xf0104586
f0101f0b:	68 17 03 00 00       	push   $0x317
f0101f10:	68 44 45 10 f0       	push   $0xf0104544
f0101f15:	e8 71 e1 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101f1a:	68 dc 46 10 f0       	push   $0xf01046dc
f0101f1f:	68 86 45 10 f0       	push   $0xf0104586
f0101f24:	68 1a 03 00 00       	push   $0x31a
f0101f29:	68 44 45 10 f0       	push   $0xf0104544
f0101f2e:	e8 58 e1 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f33:	68 88 40 10 f0       	push   $0xf0104088
f0101f38:	68 86 45 10 f0       	push   $0xf0104586
f0101f3d:	68 1d 03 00 00       	push   $0x31d
f0101f42:	68 44 45 10 f0       	push   $0xf0104544
f0101f47:	e8 3f e1 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f4c:	68 c4 40 10 f0       	push   $0xf01040c4
f0101f51:	68 86 45 10 f0       	push   $0xf0104586
f0101f56:	68 1e 03 00 00       	push   $0x31e
f0101f5b:	68 44 45 10 f0       	push   $0xf0104544
f0101f60:	e8 26 e1 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101f65:	68 50 47 10 f0       	push   $0xf0104750
f0101f6a:	68 86 45 10 f0       	push   $0xf0104586
f0101f6f:	68 1f 03 00 00       	push   $0x31f
f0101f74:	68 44 45 10 f0       	push   $0xf0104544
f0101f79:	e8 0d e1 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101f7e:	68 dc 46 10 f0       	push   $0xf01046dc
f0101f83:	68 86 45 10 f0       	push   $0xf0104586
f0101f88:	68 23 03 00 00       	push   $0x323
f0101f8d:	68 44 45 10 f0       	push   $0xf0104544
f0101f92:	e8 f4 e0 ff ff       	call   f010008b <_panic>

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f97:	50                   	push   %eax
f0101f98:	68 a4 3d 10 f0       	push   $0xf0103da4
f0101f9d:	68 26 03 00 00       	push   $0x326
f0101fa2:	68 44 45 10 f0       	push   $0xf0104544
f0101fa7:	e8 df e0 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101fac:	68 f4 40 10 f0       	push   $0xf01040f4
f0101fb1:	68 86 45 10 f0       	push   $0xf0104586
f0101fb6:	68 27 03 00 00       	push   $0x327
f0101fbb:	68 44 45 10 f0       	push   $0xf0104544
f0101fc0:	e8 c6 e0 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101fc5:	68 34 41 10 f0       	push   $0xf0104134
f0101fca:	68 86 45 10 f0       	push   $0xf0104586
f0101fcf:	68 2a 03 00 00       	push   $0x32a
f0101fd4:	68 44 45 10 f0       	push   $0xf0104544
f0101fd9:	e8 ad e0 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101fde:	68 c4 40 10 f0       	push   $0xf01040c4
f0101fe3:	68 86 45 10 f0       	push   $0xf0104586
f0101fe8:	68 2b 03 00 00       	push   $0x32b
f0101fed:	68 44 45 10 f0       	push   $0xf0104544
f0101ff2:	e8 94 e0 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f0101ff7:	68 50 47 10 f0       	push   $0xf0104750
f0101ffc:	68 86 45 10 f0       	push   $0xf0104586
f0102001:	68 2c 03 00 00       	push   $0x32c
f0102006:	68 44 45 10 f0       	push   $0xf0104544
f010200b:	e8 7b e0 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102010:	68 74 41 10 f0       	push   $0xf0104174
f0102015:	68 86 45 10 f0       	push   $0xf0104586
f010201a:	68 2d 03 00 00       	push   $0x32d
f010201f:	68 44 45 10 f0       	push   $0xf0104544
f0102024:	e8 62 e0 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102029:	68 61 47 10 f0       	push   $0xf0104761
f010202e:	68 86 45 10 f0       	push   $0xf0104586
f0102033:	68 2e 03 00 00       	push   $0x32e
f0102038:	68 44 45 10 f0       	push   $0xf0104544
f010203d:	e8 49 e0 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102042:	68 88 40 10 f0       	push   $0xf0104088
f0102047:	68 86 45 10 f0       	push   $0xf0104586
f010204c:	68 31 03 00 00       	push   $0x331
f0102051:	68 44 45 10 f0       	push   $0xf0104544
f0102056:	e8 30 e0 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010205b:	68 a8 41 10 f0       	push   $0xf01041a8
f0102060:	68 86 45 10 f0       	push   $0xf0104586
f0102065:	68 32 03 00 00       	push   $0x332
f010206a:	68 44 45 10 f0       	push   $0xf0104544
f010206f:	e8 17 e0 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102074:	68 dc 41 10 f0       	push   $0xf01041dc
f0102079:	68 86 45 10 f0       	push   $0xf0104586
f010207e:	68 33 03 00 00       	push   $0x333
f0102083:	68 44 45 10 f0       	push   $0xf0104544
f0102088:	e8 fe df ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010208d:	68 14 42 10 f0       	push   $0xf0104214
f0102092:	68 86 45 10 f0       	push   $0xf0104586
f0102097:	68 36 03 00 00       	push   $0x336
f010209c:	68 44 45 10 f0       	push   $0xf0104544
f01020a1:	e8 e5 df ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01020a6:	68 4c 42 10 f0       	push   $0xf010424c
f01020ab:	68 86 45 10 f0       	push   $0xf0104586
f01020b0:	68 39 03 00 00       	push   $0x339
f01020b5:	68 44 45 10 f0       	push   $0xf0104544
f01020ba:	e8 cc df ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01020bf:	68 dc 41 10 f0       	push   $0xf01041dc
f01020c4:	68 86 45 10 f0       	push   $0xf0104586
f01020c9:	68 3a 03 00 00       	push   $0x33a
f01020ce:	68 44 45 10 f0       	push   $0xf0104544
f01020d3:	e8 b3 df ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01020d8:	68 88 42 10 f0       	push   $0xf0104288
f01020dd:	68 86 45 10 f0       	push   $0xf0104586
f01020e2:	68 3d 03 00 00       	push   $0x33d
f01020e7:	68 44 45 10 f0       	push   $0xf0104544
f01020ec:	e8 9a df ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020f1:	68 b4 42 10 f0       	push   $0xf01042b4
f01020f6:	68 86 45 10 f0       	push   $0xf0104586
f01020fb:	68 3e 03 00 00       	push   $0x33e
f0102100:	68 44 45 10 f0       	push   $0xf0104544
f0102105:	e8 81 df ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010210a:	68 77 47 10 f0       	push   $0xf0104777
f010210f:	68 86 45 10 f0       	push   $0xf0104586
f0102114:	68 40 03 00 00       	push   $0x340
f0102119:	68 44 45 10 f0       	push   $0xf0104544
f010211e:	e8 68 df ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0102123:	68 88 47 10 f0       	push   $0xf0104788
f0102128:	68 86 45 10 f0       	push   $0xf0104586
f010212d:	68 41 03 00 00       	push   $0x341
f0102132:	68 44 45 10 f0       	push   $0xf0104544
f0102137:	e8 4f df ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010213c:	68 e4 42 10 f0       	push   $0xf01042e4
f0102141:	68 86 45 10 f0       	push   $0xf0104586
f0102146:	68 44 03 00 00       	push   $0x344
f010214b:	68 44 45 10 f0       	push   $0xf0104544
f0102150:	e8 36 df ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102155:	68 08 43 10 f0       	push   $0xf0104308
f010215a:	68 86 45 10 f0       	push   $0xf0104586
f010215f:	68 48 03 00 00       	push   $0x348
f0102164:	68 44 45 10 f0       	push   $0xf0104544
f0102169:	e8 1d df ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010216e:	68 b4 42 10 f0       	push   $0xf01042b4
f0102173:	68 86 45 10 f0       	push   $0xf0104586
f0102178:	68 49 03 00 00       	push   $0x349
f010217d:	68 44 45 10 f0       	push   $0xf0104544
f0102182:	e8 04 df ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0102187:	68 2e 47 10 f0       	push   $0xf010472e
f010218c:	68 86 45 10 f0       	push   $0xf0104586
f0102191:	68 4a 03 00 00       	push   $0x34a
f0102196:	68 44 45 10 f0       	push   $0xf0104544
f010219b:	e8 eb de ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f01021a0:	68 88 47 10 f0       	push   $0xf0104788
f01021a5:	68 86 45 10 f0       	push   $0xf0104586
f01021aa:	68 4b 03 00 00       	push   $0x34b
f01021af:	68 44 45 10 f0       	push   $0xf0104544
f01021b4:	e8 d2 de ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01021b9:	68 2c 43 10 f0       	push   $0xf010432c
f01021be:	68 86 45 10 f0       	push   $0xf0104586
f01021c3:	68 4e 03 00 00       	push   $0x34e
f01021c8:	68 44 45 10 f0       	push   $0xf0104544
f01021cd:	e8 b9 de ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f01021d2:	68 99 47 10 f0       	push   $0xf0104799
f01021d7:	68 86 45 10 f0       	push   $0xf0104586
f01021dc:	68 4f 03 00 00       	push   $0x34f
f01021e1:	68 44 45 10 f0       	push   $0xf0104544
f01021e6:	e8 a0 de ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f01021eb:	68 a5 47 10 f0       	push   $0xf01047a5
f01021f0:	68 86 45 10 f0       	push   $0xf0104586
f01021f5:	68 50 03 00 00       	push   $0x350
f01021fa:	68 44 45 10 f0       	push   $0xf0104544
f01021ff:	e8 87 de ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102204:	68 08 43 10 f0       	push   $0xf0104308
f0102209:	68 86 45 10 f0       	push   $0xf0104586
f010220e:	68 54 03 00 00       	push   $0x354
f0102213:	68 44 45 10 f0       	push   $0xf0104544
f0102218:	e8 6e de ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010221d:	68 64 43 10 f0       	push   $0xf0104364
f0102222:	68 86 45 10 f0       	push   $0xf0104586
f0102227:	68 55 03 00 00       	push   $0x355
f010222c:	68 44 45 10 f0       	push   $0xf0104544
f0102231:	e8 55 de ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0102236:	68 ba 47 10 f0       	push   $0xf01047ba
f010223b:	68 86 45 10 f0       	push   $0xf0104586
f0102240:	68 56 03 00 00       	push   $0x356
f0102245:	68 44 45 10 f0       	push   $0xf0104544
f010224a:	e8 3c de ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f010224f:	68 88 47 10 f0       	push   $0xf0104788
f0102254:	68 86 45 10 f0       	push   $0xf0104586
f0102259:	68 57 03 00 00       	push   $0x357
f010225e:	68 44 45 10 f0       	push   $0xf0104544
f0102263:	e8 23 de ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102268:	68 8c 43 10 f0       	push   $0xf010438c
f010226d:	68 86 45 10 f0       	push   $0xf0104586
f0102272:	68 5a 03 00 00       	push   $0x35a
f0102277:	68 44 45 10 f0       	push   $0xf0104544
f010227c:	e8 0a de ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102281:	68 dc 46 10 f0       	push   $0xf01046dc
f0102286:	68 86 45 10 f0       	push   $0xf0104586
f010228b:	68 5d 03 00 00       	push   $0x35d
f0102290:	68 44 45 10 f0       	push   $0xf0104544
f0102295:	e8 f1 dd ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010229a:	68 30 40 10 f0       	push   $0xf0104030
f010229f:	68 86 45 10 f0       	push   $0xf0104586
f01022a4:	68 60 03 00 00       	push   $0x360
f01022a9:	68 44 45 10 f0       	push   $0xf0104544
f01022ae:	e8 d8 dd ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
	assert(pp0->pp_ref == 1);
f01022b3:	68 3f 47 10 f0       	push   $0xf010473f
f01022b8:	68 86 45 10 f0       	push   $0xf0104586
f01022bd:	68 62 03 00 00       	push   $0x362
f01022c2:	68 44 45 10 f0       	push   $0xf0104544
f01022c7:	e8 bf dd ff ff       	call   f010008b <_panic>
f01022cc:	52                   	push   %edx
f01022cd:	68 a4 3d 10 f0       	push   $0xf0103da4
f01022d2:	68 69 03 00 00       	push   $0x369
f01022d7:	68 44 45 10 f0       	push   $0xf0104544
f01022dc:	e8 aa dd ff ff       	call   f010008b <_panic>
	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
	assert(ptep == ptep1 + PTX(va));
f01022e1:	68 cb 47 10 f0       	push   $0xf01047cb
f01022e6:	68 86 45 10 f0       	push   $0xf0104586
f01022eb:	68 6a 03 00 00       	push   $0x36a
f01022f0:	68 44 45 10 f0       	push   $0xf0104544
f01022f5:	e8 91 dd ff ff       	call   f010008b <_panic>
f01022fa:	50                   	push   %eax
f01022fb:	68 a4 3d 10 f0       	push   $0xf0103da4
f0102300:	6a 52                	push   $0x52
f0102302:	68 6c 45 10 f0       	push   $0xf010456c
f0102307:	e8 7f dd ff ff       	call   f010008b <_panic>
f010230c:	52                   	push   %edx
f010230d:	68 a4 3d 10 f0       	push   $0xf0103da4
f0102312:	6a 52                	push   $0x52
f0102314:	68 6c 45 10 f0       	push   $0xf010456c
f0102319:	e8 6d dd ff ff       	call   f010008b <_panic>
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010231e:	68 e3 47 10 f0       	push   $0xf01047e3
f0102323:	68 86 45 10 f0       	push   $0xf0104586
f0102328:	68 74 03 00 00       	push   $0x374
f010232d:	68 44 45 10 f0       	push   $0xf0104544
f0102332:	e8 54 dd ff ff       	call   f010008b <_panic>

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102337:	50                   	push   %eax
f0102338:	68 b0 3e 10 f0       	push   $0xf0103eb0
f010233d:	68 bd 00 00 00       	push   $0xbd
f0102342:	68 44 45 10 f0       	push   $0xf0104544
f0102347:	e8 3f dd ff ff       	call   f010008b <_panic>
f010234c:	50                   	push   %eax
f010234d:	68 b0 3e 10 f0       	push   $0xf0103eb0
f0102352:	68 ca 00 00 00       	push   $0xca
f0102357:	68 44 45 10 f0       	push   $0xf0104544
f010235c:	e8 2a dd ff ff       	call   f010008b <_panic>
f0102361:	57                   	push   %edi
f0102362:	68 b0 3e 10 f0       	push   $0xf0103eb0
f0102367:	68 b6 02 00 00       	push   $0x2b6
f010236c:	68 44 45 10 f0       	push   $0xf0104544
f0102371:	e8 15 dd ff ff       	call   f010008b <_panic>
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102376:	68 b0 43 10 f0       	push   $0xf01043b0
f010237b:	68 86 45 10 f0       	push   $0xf0104586
f0102380:	68 b6 02 00 00       	push   $0x2b6
f0102385:	68 44 45 10 f0       	push   $0xf0104544
f010238a:	e8 fc dc ff ff       	call   f010008b <_panic>


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010238f:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102392:	c1 e7 0c             	shl    $0xc,%edi
f0102395:	bb 00 00 00 00       	mov    $0x0,%ebx
f010239a:	eb 06                	jmp    f01023a2 <mem_init+0x1303>
f010239c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01023a2:	39 fb                	cmp    %edi,%ebx
f01023a4:	73 2a                	jae    f01023d0 <mem_init+0x1331>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01023a6:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01023ac:	89 f0                	mov    %esi,%eax
f01023ae:	e8 c4 e5 ff ff       	call   f0100977 <check_va2pa>
f01023b3:	39 c3                	cmp    %eax,%ebx
f01023b5:	74 e5                	je     f010239c <mem_init+0x12fd>
f01023b7:	68 e4 43 10 f0       	push   $0xf01043e4
f01023bc:	68 86 45 10 f0       	push   $0xf0104586
f01023c1:	68 bb 02 00 00       	push   $0x2bb
f01023c6:	68 44 45 10 f0       	push   $0xf0104544
f01023cb:	e8 bb dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01023d0:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01023d5:	89 da                	mov    %ebx,%edx
f01023d7:	89 f0                	mov    %esi,%eax
f01023d9:	e8 99 e5 ff ff       	call   f0100977 <check_va2pa>
f01023de:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f01023e4:	39 d0                	cmp    %edx,%eax
f01023e6:	75 26                	jne    f010240e <mem_init+0x136f>
f01023e8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01023ee:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f01023f4:	75 df                	jne    f01023d5 <mem_init+0x1336>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01023f6:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01023fb:	89 f0                	mov    %esi,%eax
f01023fd:	e8 75 e5 ff ff       	call   f0100977 <check_va2pa>
f0102402:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102405:	75 20                	jne    f0102427 <mem_init+0x1388>
f0102407:	b8 00 00 00 00       	mov    $0x0,%eax
f010240c:	eb 59                	jmp    f0102467 <mem_init+0x13c8>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010240e:	68 0c 44 10 f0       	push   $0xf010440c
f0102413:	68 86 45 10 f0       	push   $0xf0104586
f0102418:	68 bf 02 00 00       	push   $0x2bf
f010241d:	68 44 45 10 f0       	push   $0xf0104544
f0102422:	e8 64 dc ff ff       	call   f010008b <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102427:	68 54 44 10 f0       	push   $0xf0104454
f010242c:	68 86 45 10 f0       	push   $0xf0104586
f0102431:	68 c0 02 00 00       	push   $0x2c0
f0102436:	68 44 45 10 f0       	push   $0xf0104544
f010243b:	e8 4b dc ff ff       	call   f010008b <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102440:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102444:	74 47                	je     f010248d <mem_init+0x13ee>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102446:	40                   	inc    %eax
f0102447:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f010244c:	0f 87 93 00 00 00    	ja     f01024e5 <mem_init+0x1446>
		switch (i) {
f0102452:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102457:	72 0e                	jb     f0102467 <mem_init+0x13c8>
f0102459:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010245e:	76 e0                	jbe    f0102440 <mem_init+0x13a1>
f0102460:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102465:	74 d9                	je     f0102440 <mem_init+0x13a1>
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102467:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010246c:	77 38                	ja     f01024a6 <mem_init+0x1407>
				assert(pgdir[i] & PTE_P);
				assert(pgdir[i] & PTE_W);
			} else
				assert(pgdir[i] == 0);
f010246e:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102472:	74 d2                	je     f0102446 <mem_init+0x13a7>
f0102474:	68 35 48 10 f0       	push   $0xf0104835
f0102479:	68 86 45 10 f0       	push   $0xf0104586
f010247e:	68 cf 02 00 00       	push   $0x2cf
f0102483:	68 44 45 10 f0       	push   $0xf0104544
f0102488:	e8 fe db ff ff       	call   f010008b <_panic>
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010248d:	68 13 48 10 f0       	push   $0xf0104813
f0102492:	68 86 45 10 f0       	push   $0xf0104586
f0102497:	68 c8 02 00 00       	push   $0x2c8
f010249c:	68 44 45 10 f0       	push   $0xf0104544
f01024a1:	e8 e5 db ff ff       	call   f010008b <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
				assert(pgdir[i] & PTE_P);
f01024a6:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01024a9:	f6 c2 01             	test   $0x1,%dl
f01024ac:	74 1e                	je     f01024cc <mem_init+0x142d>
				assert(pgdir[i] & PTE_W);
f01024ae:	f6 c2 02             	test   $0x2,%dl
f01024b1:	75 93                	jne    f0102446 <mem_init+0x13a7>
f01024b3:	68 24 48 10 f0       	push   $0xf0104824
f01024b8:	68 86 45 10 f0       	push   $0xf0104586
f01024bd:	68 cd 02 00 00       	push   $0x2cd
f01024c2:	68 44 45 10 f0       	push   $0xf0104544
f01024c7:	e8 bf db ff ff       	call   f010008b <_panic>
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
				assert(pgdir[i] & PTE_P);
f01024cc:	68 13 48 10 f0       	push   $0xf0104813
f01024d1:	68 86 45 10 f0       	push   $0xf0104586
f01024d6:	68 cc 02 00 00       	push   $0x2cc
f01024db:	68 44 45 10 f0       	push   $0xf0104544
f01024e0:	e8 a6 db ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01024e5:	83 ec 0c             	sub    $0xc,%esp
f01024e8:	68 84 44 10 f0       	push   $0xf0104484
f01024ed:	e8 ff 03 00 00       	call   f01028f1 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01024f2:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01024f7:	83 c4 10             	add    $0x10,%esp
f01024fa:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01024ff:	0f 86 fe 01 00 00    	jbe    f0102703 <mem_init+0x1664>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102505:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010250a:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010250d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102512:	e8 c1 e4 ff ff       	call   f01009d8 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102517:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f010251a:	83 e0 f3             	and    $0xfffffff3,%eax
f010251d:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102522:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102525:	83 ec 0c             	sub    $0xc,%esp
f0102528:	6a 00                	push   $0x0
f010252a:	e8 59 e8 ff ff       	call   f0100d88 <page_alloc>
f010252f:	89 c3                	mov    %eax,%ebx
f0102531:	83 c4 10             	add    $0x10,%esp
f0102534:	85 c0                	test   %eax,%eax
f0102536:	0f 84 dc 01 00 00    	je     f0102718 <mem_init+0x1679>
	assert((pp1 = page_alloc(0)));
f010253c:	83 ec 0c             	sub    $0xc,%esp
f010253f:	6a 00                	push   $0x0
f0102541:	e8 42 e8 ff ff       	call   f0100d88 <page_alloc>
f0102546:	89 c7                	mov    %eax,%edi
f0102548:	83 c4 10             	add    $0x10,%esp
f010254b:	85 c0                	test   %eax,%eax
f010254d:	0f 84 de 01 00 00    	je     f0102731 <mem_init+0x1692>
	assert((pp2 = page_alloc(0)));
f0102553:	83 ec 0c             	sub    $0xc,%esp
f0102556:	6a 00                	push   $0x0
f0102558:	e8 2b e8 ff ff       	call   f0100d88 <page_alloc>
f010255d:	89 c6                	mov    %eax,%esi
f010255f:	83 c4 10             	add    $0x10,%esp
f0102562:	85 c0                	test   %eax,%eax
f0102564:	0f 84 e0 01 00 00    	je     f010274a <mem_init+0x16ab>
	page_free(pp0);
f010256a:	83 ec 0c             	sub    $0xc,%esp
f010256d:	53                   	push   %ebx
f010256e:	e8 87 e8 ff ff       	call   f0100dfa <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102573:	89 f8                	mov    %edi,%eax
f0102575:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f010257b:	c1 f8 03             	sar    $0x3,%eax
f010257e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102581:	89 c2                	mov    %eax,%edx
f0102583:	c1 ea 0c             	shr    $0xc,%edx
f0102586:	83 c4 10             	add    $0x10,%esp
f0102589:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f010258f:	0f 83 ce 01 00 00    	jae    f0102763 <mem_init+0x16c4>
	memset(page2kva(pp1), 1, PGSIZE);
f0102595:	83 ec 04             	sub    $0x4,%esp
f0102598:	68 00 10 00 00       	push   $0x1000
f010259d:	6a 01                	push   $0x1
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f010259f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025a4:	50                   	push   %eax
f01025a5:	e8 8f 0e 00 00       	call   f0103439 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025aa:	89 f0                	mov    %esi,%eax
f01025ac:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f01025b2:	c1 f8 03             	sar    $0x3,%eax
f01025b5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025b8:	89 c2                	mov    %eax,%edx
f01025ba:	c1 ea 0c             	shr    $0xc,%edx
f01025bd:	83 c4 10             	add    $0x10,%esp
f01025c0:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f01025c6:	0f 83 a9 01 00 00    	jae    f0102775 <mem_init+0x16d6>
	memset(page2kva(pp2), 2, PGSIZE);
f01025cc:	83 ec 04             	sub    $0x4,%esp
f01025cf:	68 00 10 00 00       	push   $0x1000
f01025d4:	6a 02                	push   $0x2
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
	return (void *)(pa + KERNBASE);
f01025d6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025db:	50                   	push   %eax
f01025dc:	e8 58 0e 00 00       	call   f0103439 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01025e1:	6a 02                	push   $0x2
f01025e3:	68 00 10 00 00       	push   $0x1000
f01025e8:	57                   	push   %edi
f01025e9:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f01025ef:	e8 38 ea ff ff       	call   f010102c <page_insert>
	assert(pp1->pp_ref == 1);
f01025f4:	83 c4 20             	add    $0x20,%esp
f01025f7:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01025fc:	0f 85 85 01 00 00    	jne    f0102787 <mem_init+0x16e8>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102602:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102609:	01 01 01 
f010260c:	0f 85 8e 01 00 00    	jne    f01027a0 <mem_init+0x1701>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102612:	6a 02                	push   $0x2
f0102614:	68 00 10 00 00       	push   $0x1000
f0102619:	56                   	push   %esi
f010261a:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0102620:	e8 07 ea ff ff       	call   f010102c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102625:	83 c4 10             	add    $0x10,%esp
f0102628:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010262f:	02 02 02 
f0102632:	0f 85 81 01 00 00    	jne    f01027b9 <mem_init+0x171a>
	assert(pp2->pp_ref == 1);
f0102638:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010263d:	0f 85 8f 01 00 00    	jne    f01027d2 <mem_init+0x1733>
	assert(pp1->pp_ref == 0);
f0102643:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102648:	0f 85 9d 01 00 00    	jne    f01027eb <mem_init+0x174c>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010264e:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102655:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102658:	89 f0                	mov    %esi,%eax
f010265a:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f0102660:	c1 f8 03             	sar    $0x3,%eax
f0102663:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102666:	89 c2                	mov    %eax,%edx
f0102668:	c1 ea 0c             	shr    $0xc,%edx
f010266b:	3b 15 68 79 11 f0    	cmp    0xf0117968,%edx
f0102671:	0f 83 8d 01 00 00    	jae    f0102804 <mem_init+0x1765>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102677:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f010267e:	03 03 03 
f0102681:	0f 85 8f 01 00 00    	jne    f0102816 <mem_init+0x1777>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102687:	83 ec 08             	sub    $0x8,%esp
f010268a:	68 00 10 00 00       	push   $0x1000
f010268f:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0102695:	e8 50 e9 ff ff       	call   f0100fea <page_remove>
	assert(pp2->pp_ref == 0);
f010269a:	83 c4 10             	add    $0x10,%esp
f010269d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01026a2:	0f 85 87 01 00 00    	jne    f010282f <mem_init+0x1790>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026a8:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
f01026ae:	8b 11                	mov    (%ecx),%edx
f01026b0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01026b6:	89 d8                	mov    %ebx,%eax
f01026b8:	2b 05 70 79 11 f0    	sub    0xf0117970,%eax
f01026be:	c1 f8 03             	sar    $0x3,%eax
f01026c1:	c1 e0 0c             	shl    $0xc,%eax
f01026c4:	39 c2                	cmp    %eax,%edx
f01026c6:	0f 85 7c 01 00 00    	jne    f0102848 <mem_init+0x17a9>
	kern_pgdir[0] = 0;
f01026cc:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01026d2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026d7:	0f 85 84 01 00 00    	jne    f0102861 <mem_init+0x17c2>
	pp0->pp_ref = 0;
f01026dd:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01026e3:	83 ec 0c             	sub    $0xc,%esp
f01026e6:	53                   	push   %ebx
f01026e7:	e8 0e e7 ff ff       	call   f0100dfa <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01026ec:	c7 04 24 18 45 10 f0 	movl   $0xf0104518,(%esp)
f01026f3:	e8 f9 01 00 00       	call   f01028f1 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01026f8:	83 c4 10             	add    $0x10,%esp
f01026fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01026fe:	5b                   	pop    %ebx
f01026ff:	5e                   	pop    %esi
f0102700:	5f                   	pop    %edi
f0102701:	5d                   	pop    %ebp
f0102702:	c3                   	ret    

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102703:	50                   	push   %eax
f0102704:	68 b0 3e 10 f0       	push   $0xf0103eb0
f0102709:	68 e1 00 00 00       	push   $0xe1
f010270e:	68 44 45 10 f0       	push   $0xf0104544
f0102713:	e8 73 d9 ff ff       	call   f010008b <_panic>
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102718:	68 31 46 10 f0       	push   $0xf0104631
f010271d:	68 86 45 10 f0       	push   $0xf0104586
f0102722:	68 8f 03 00 00       	push   $0x38f
f0102727:	68 44 45 10 f0       	push   $0xf0104544
f010272c:	e8 5a d9 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0102731:	68 47 46 10 f0       	push   $0xf0104647
f0102736:	68 86 45 10 f0       	push   $0xf0104586
f010273b:	68 90 03 00 00       	push   $0x390
f0102740:	68 44 45 10 f0       	push   $0xf0104544
f0102745:	e8 41 d9 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010274a:	68 5d 46 10 f0       	push   $0xf010465d
f010274f:	68 86 45 10 f0       	push   $0xf0104586
f0102754:	68 91 03 00 00       	push   $0x391
f0102759:	68 44 45 10 f0       	push   $0xf0104544
f010275e:	e8 28 d9 ff ff       	call   f010008b <_panic>

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102763:	50                   	push   %eax
f0102764:	68 a4 3d 10 f0       	push   $0xf0103da4
f0102769:	6a 52                	push   $0x52
f010276b:	68 6c 45 10 f0       	push   $0xf010456c
f0102770:	e8 16 d9 ff ff       	call   f010008b <_panic>
f0102775:	50                   	push   %eax
f0102776:	68 a4 3d 10 f0       	push   $0xf0103da4
f010277b:	6a 52                	push   $0x52
f010277d:	68 6c 45 10 f0       	push   $0xf010456c
f0102782:	e8 04 d9 ff ff       	call   f010008b <_panic>
	page_free(pp0);
	memset(page2kva(pp1), 1, PGSIZE);
	memset(page2kva(pp2), 2, PGSIZE);
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
	assert(pp1->pp_ref == 1);
f0102787:	68 2e 47 10 f0       	push   $0xf010472e
f010278c:	68 86 45 10 f0       	push   $0xf0104586
f0102791:	68 96 03 00 00       	push   $0x396
f0102796:	68 44 45 10 f0       	push   $0xf0104544
f010279b:	e8 eb d8 ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01027a0:	68 a4 44 10 f0       	push   $0xf01044a4
f01027a5:	68 86 45 10 f0       	push   $0xf0104586
f01027aa:	68 97 03 00 00       	push   $0x397
f01027af:	68 44 45 10 f0       	push   $0xf0104544
f01027b4:	e8 d2 d8 ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01027b9:	68 c8 44 10 f0       	push   $0xf01044c8
f01027be:	68 86 45 10 f0       	push   $0xf0104586
f01027c3:	68 99 03 00 00       	push   $0x399
f01027c8:	68 44 45 10 f0       	push   $0xf0104544
f01027cd:	e8 b9 d8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01027d2:	68 50 47 10 f0       	push   $0xf0104750
f01027d7:	68 86 45 10 f0       	push   $0xf0104586
f01027dc:	68 9a 03 00 00       	push   $0x39a
f01027e1:	68 44 45 10 f0       	push   $0xf0104544
f01027e6:	e8 a0 d8 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f01027eb:	68 ba 47 10 f0       	push   $0xf01047ba
f01027f0:	68 86 45 10 f0       	push   $0xf0104586
f01027f5:	68 9b 03 00 00       	push   $0x39b
f01027fa:	68 44 45 10 f0       	push   $0xf0104544
f01027ff:	e8 87 d8 ff ff       	call   f010008b <_panic>
f0102804:	50                   	push   %eax
f0102805:	68 a4 3d 10 f0       	push   $0xf0103da4
f010280a:	6a 52                	push   $0x52
f010280c:	68 6c 45 10 f0       	push   $0xf010456c
f0102811:	e8 75 d8 ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102816:	68 ec 44 10 f0       	push   $0xf01044ec
f010281b:	68 86 45 10 f0       	push   $0xf0104586
f0102820:	68 9d 03 00 00       	push   $0x39d
f0102825:	68 44 45 10 f0       	push   $0xf0104544
f010282a:	e8 5c d8 ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
	assert(pp2->pp_ref == 0);
f010282f:	68 88 47 10 f0       	push   $0xf0104788
f0102834:	68 86 45 10 f0       	push   $0xf0104586
f0102839:	68 9f 03 00 00       	push   $0x39f
f010283e:	68 44 45 10 f0       	push   $0xf0104544
f0102843:	e8 43 d8 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102848:	68 30 40 10 f0       	push   $0xf0104030
f010284d:	68 86 45 10 f0       	push   $0xf0104586
f0102852:	68 a2 03 00 00       	push   $0x3a2
f0102857:	68 44 45 10 f0       	push   $0xf0104544
f010285c:	e8 2a d8 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
	assert(pp0->pp_ref == 1);
f0102861:	68 3f 47 10 f0       	push   $0xf010473f
f0102866:	68 86 45 10 f0       	push   $0xf0104586
f010286b:	68 a4 03 00 00       	push   $0x3a4
f0102870:	68 44 45 10 f0       	push   $0xf0104544
f0102875:	e8 11 d8 ff ff       	call   f010008b <_panic>

f010287a <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010287a:	55                   	push   %ebp
f010287b:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010287d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102880:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102883:	5d                   	pop    %ebp
f0102884:	c3                   	ret    
f0102885:	00 00                	add    %al,(%eax)
	...

f0102888 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102888:	55                   	push   %ebp
f0102889:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010288b:	ba 70 00 00 00       	mov    $0x70,%edx
f0102890:	8b 45 08             	mov    0x8(%ebp),%eax
f0102893:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102894:	ba 71 00 00 00       	mov    $0x71,%edx
f0102899:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010289a:	0f b6 c0             	movzbl %al,%eax
}
f010289d:	5d                   	pop    %ebp
f010289e:	c3                   	ret    

f010289f <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010289f:	55                   	push   %ebp
f01028a0:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01028a2:	ba 70 00 00 00       	mov    $0x70,%edx
f01028a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01028aa:	ee                   	out    %al,(%dx)
f01028ab:	ba 71 00 00 00       	mov    $0x71,%edx
f01028b0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028b3:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01028b4:	5d                   	pop    %ebp
f01028b5:	c3                   	ret    
	...

f01028b8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01028b8:	55                   	push   %ebp
f01028b9:	89 e5                	mov    %esp,%ebp
f01028bb:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01028be:	ff 75 08             	pushl  0x8(%ebp)
f01028c1:	e8 11 dd ff ff       	call   f01005d7 <cputchar>
	*cnt++;
}
f01028c6:	83 c4 10             	add    $0x10,%esp
f01028c9:	c9                   	leave  
f01028ca:	c3                   	ret    

f01028cb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01028cb:	55                   	push   %ebp
f01028cc:	89 e5                	mov    %esp,%ebp
f01028ce:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01028d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01028d8:	ff 75 0c             	pushl  0xc(%ebp)
f01028db:	ff 75 08             	pushl  0x8(%ebp)
f01028de:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01028e1:	50                   	push   %eax
f01028e2:	68 b8 28 10 f0       	push   $0xf01028b8
f01028e7:	e8 2e 04 00 00       	call   f0102d1a <vprintfmt>
	return cnt;
}
f01028ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01028ef:	c9                   	leave  
f01028f0:	c3                   	ret    

f01028f1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01028f1:	55                   	push   %ebp
f01028f2:	89 e5                	mov    %esp,%ebp
f01028f4:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01028f7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01028fa:	50                   	push   %eax
f01028fb:	ff 75 08             	pushl  0x8(%ebp)
f01028fe:	e8 c8 ff ff ff       	call   f01028cb <vcprintf>
	va_end(ap);

	return cnt;
}
f0102903:	c9                   	leave  
f0102904:	c3                   	ret    
f0102905:	00 00                	add    %al,(%eax)
	...

f0102908 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102908:	55                   	push   %ebp
f0102909:	89 e5                	mov    %esp,%ebp
f010290b:	57                   	push   %edi
f010290c:	56                   	push   %esi
f010290d:	53                   	push   %ebx
f010290e:	83 ec 14             	sub    $0x14,%esp
f0102911:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102914:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102917:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010291a:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010291d:	8b 1a                	mov    (%edx),%ebx
f010291f:	8b 01                	mov    (%ecx),%eax
f0102921:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102924:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010292b:	eb 34                	jmp    f0102961 <stab_binsearch+0x59>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f010292d:	48                   	dec    %eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010292e:	39 c3                	cmp    %eax,%ebx
f0102930:	7f 2c                	jg     f010295e <stab_binsearch+0x56>
f0102932:	0f b6 0a             	movzbl (%edx),%ecx
f0102935:	83 ea 0c             	sub    $0xc,%edx
f0102938:	39 f9                	cmp    %edi,%ecx
f010293a:	75 f1                	jne    f010292d <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010293c:	8d 14 00             	lea    (%eax,%eax,1),%edx
f010293f:	01 c2                	add    %eax,%edx
f0102941:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102944:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0102948:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010294b:	76 37                	jbe    f0102984 <stab_binsearch+0x7c>
			*region_left = m;
f010294d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102950:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102952:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102955:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010295c:	eb 03                	jmp    f0102961 <stab_binsearch+0x59>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010295e:	8d 5e 01             	lea    0x1(%esi),%ebx
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102961:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102964:	7f 48                	jg     f01029ae <stab_binsearch+0xa6>
		int true_m = (l + r) / 2, m = true_m;
f0102966:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102969:	01 d8                	add    %ebx,%eax
f010296b:	89 c6                	mov    %eax,%esi
f010296d:	c1 ee 1f             	shr    $0x1f,%esi
f0102970:	01 c6                	add    %eax,%esi
f0102972:	d1 fe                	sar    %esi
f0102974:	8d 04 36             	lea    (%esi,%esi,1),%eax
f0102977:	01 f0                	add    %esi,%eax
f0102979:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010297c:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0102980:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102982:	eb aa                	jmp    f010292e <stab_binsearch+0x26>
		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102984:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102987:	73 12                	jae    f010299b <stab_binsearch+0x93>
			*region_right = m - 1;
f0102989:	48                   	dec    %eax
f010298a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010298d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0102990:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102992:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0102999:	eb c6                	jmp    f0102961 <stab_binsearch+0x59>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010299b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010299e:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01029a0:	ff 45 0c             	incl   0xc(%ebp)
f01029a3:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01029a5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01029ac:	eb b3                	jmp    f0102961 <stab_binsearch+0x59>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01029ae:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01029b2:	74 18                	je     f01029cc <stab_binsearch+0xc4>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01029b4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01029b7:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01029b9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029bc:	8b 0e                	mov    (%esi),%ecx
f01029be:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01029c1:	01 c2                	add    %eax,%edx
f01029c3:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01029c6:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01029ca:	eb 0e                	jmp    f01029da <stab_binsearch+0xd2>
			addr++;
		}
	}

	if (!any_matches)
		*region_right = *region_left - 1;
f01029cc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01029cf:	8b 00                	mov    (%eax),%eax
f01029d1:	48                   	dec    %eax
f01029d2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01029d5:	89 07                	mov    %eax,(%edi)
f01029d7:	eb 14                	jmp    f01029ed <stab_binsearch+0xe5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01029d9:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01029da:	39 c8                	cmp    %ecx,%eax
f01029dc:	7e 0a                	jle    f01029e8 <stab_binsearch+0xe0>
		     l > *region_left && stabs[l].n_type != type;
f01029de:	0f b6 1a             	movzbl (%edx),%ebx
f01029e1:	83 ea 0c             	sub    $0xc,%edx
f01029e4:	39 df                	cmp    %ebx,%edi
f01029e6:	75 f1                	jne    f01029d9 <stab_binsearch+0xd1>
		     l--)
			/* do nothing */;
		*region_left = l;
f01029e8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01029eb:	89 07                	mov    %eax,(%edi)
	}
}
f01029ed:	83 c4 14             	add    $0x14,%esp
f01029f0:	5b                   	pop    %ebx
f01029f1:	5e                   	pop    %esi
f01029f2:	5f                   	pop    %edi
f01029f3:	5d                   	pop    %ebp
f01029f4:	c3                   	ret    

f01029f5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01029f5:	55                   	push   %ebp
f01029f6:	89 e5                	mov    %esp,%ebp
f01029f8:	57                   	push   %edi
f01029f9:	56                   	push   %esi
f01029fa:	53                   	push   %ebx
f01029fb:	83 ec 3c             	sub    $0x3c,%esp
f01029fe:	8b 75 08             	mov    0x8(%ebp),%esi
f0102a01:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102a04:	c7 03 43 48 10 f0    	movl   $0xf0104843,(%ebx)
	info->eip_line = 0;
f0102a0a:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102a11:	c7 43 08 43 48 10 f0 	movl   $0xf0104843,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102a18:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102a1f:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102a22:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102a29:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102a2f:	0f 86 3a 01 00 00    	jbe    f0102b6f <debuginfo_eip+0x17a>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102a35:	b8 8c cd 10 f0       	mov    $0xf010cd8c,%eax
f0102a3a:	3d dd af 10 f0       	cmp    $0xf010afdd,%eax
f0102a3f:	0f 86 bf 01 00 00    	jbe    f0102c04 <debuginfo_eip+0x20f>
f0102a45:	80 3d 8b cd 10 f0 00 	cmpb   $0x0,0xf010cd8b
f0102a4c:	0f 85 b9 01 00 00    	jne    f0102c0b <debuginfo_eip+0x216>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102a52:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102a59:	ba dc af 10 f0       	mov    $0xf010afdc,%edx
f0102a5e:	81 ea 78 4a 10 f0    	sub    $0xf0104a78,%edx
f0102a64:	c1 fa 02             	sar    $0x2,%edx
f0102a67:	8d 04 92             	lea    (%edx,%edx,4),%eax
f0102a6a:	8d 04 82             	lea    (%edx,%eax,4),%eax
f0102a6d:	8d 04 82             	lea    (%edx,%eax,4),%eax
f0102a70:	89 c1                	mov    %eax,%ecx
f0102a72:	c1 e1 08             	shl    $0x8,%ecx
f0102a75:	01 c8                	add    %ecx,%eax
f0102a77:	89 c1                	mov    %eax,%ecx
f0102a79:	c1 e1 10             	shl    $0x10,%ecx
f0102a7c:	01 c8                	add    %ecx,%eax
f0102a7e:	01 c0                	add    %eax,%eax
f0102a80:	8d 44 02 ff          	lea    -0x1(%edx,%eax,1),%eax
f0102a84:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102a87:	83 ec 08             	sub    $0x8,%esp
f0102a8a:	56                   	push   %esi
f0102a8b:	6a 64                	push   $0x64
f0102a8d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102a90:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102a93:	b8 78 4a 10 f0       	mov    $0xf0104a78,%eax
f0102a98:	e8 6b fe ff ff       	call   f0102908 <stab_binsearch>
	if (lfile == 0)
f0102a9d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102aa0:	83 c4 10             	add    $0x10,%esp
f0102aa3:	85 c0                	test   %eax,%eax
f0102aa5:	0f 84 67 01 00 00    	je     f0102c12 <debuginfo_eip+0x21d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102aab:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102aae:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ab1:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102ab4:	83 ec 08             	sub    $0x8,%esp
f0102ab7:	56                   	push   %esi
f0102ab8:	6a 24                	push   $0x24
f0102aba:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102abd:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102ac0:	b8 78 4a 10 f0       	mov    $0xf0104a78,%eax
f0102ac5:	e8 3e fe ff ff       	call   f0102908 <stab_binsearch>

	if (lfun <= rfun) {
f0102aca:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102acd:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102ad0:	83 c4 10             	add    $0x10,%esp
f0102ad3:	39 d0                	cmp    %edx,%eax
f0102ad5:	0f 8f a8 00 00 00    	jg     f0102b83 <debuginfo_eip+0x18e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102adb:	8d 0c 00             	lea    (%eax,%eax,1),%ecx
f0102ade:	01 c1                	add    %eax,%ecx
f0102ae0:	c1 e1 02             	shl    $0x2,%ecx
f0102ae3:	8d b9 78 4a 10 f0    	lea    -0xfefb588(%ecx),%edi
f0102ae9:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102aec:	8b 89 78 4a 10 f0    	mov    -0xfefb588(%ecx),%ecx
f0102af2:	bf 8c cd 10 f0       	mov    $0xf010cd8c,%edi
f0102af7:	81 ef dd af 10 f0    	sub    $0xf010afdd,%edi
f0102afd:	39 f9                	cmp    %edi,%ecx
f0102aff:	73 09                	jae    f0102b0a <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102b01:	81 c1 dd af 10 f0    	add    $0xf010afdd,%ecx
f0102b07:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102b0a:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102b0d:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102b10:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102b13:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102b15:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102b18:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102b1b:	83 ec 08             	sub    $0x8,%esp
f0102b1e:	6a 3a                	push   $0x3a
f0102b20:	ff 73 08             	pushl  0x8(%ebx)
f0102b23:	e8 f9 08 00 00       	call   f0103421 <strfind>
f0102b28:	2b 43 08             	sub    0x8(%ebx),%eax
f0102b2b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
  stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); 
f0102b2e:	83 c4 08             	add    $0x8,%esp
f0102b31:	56                   	push   %esi
f0102b32:	6a 44                	push   $0x44
f0102b34:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102b37:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102b3a:	b8 78 4a 10 f0       	mov    $0xf0104a78,%eax
f0102b3f:	e8 c4 fd ff ff       	call   f0102908 <stab_binsearch>
  if(lline > rline) {
f0102b44:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102b47:	83 c4 10             	add    $0x10,%esp
f0102b4a:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0102b4d:	0f 8f c6 00 00 00    	jg     f0102c19 <debuginfo_eip+0x224>
    return -1;
  } else {
    info->eip_line = stabs[lline].n_desc;
f0102b53:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0102b56:	01 d0                	add    %edx,%eax
f0102b58:	c1 e0 02             	shl    $0x2,%eax
f0102b5b:	0f b7 88 7e 4a 10 f0 	movzwl -0xfefb582(%eax),%ecx
f0102b62:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102b65:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102b68:	05 7c 4a 10 f0       	add    $0xf0104a7c,%eax
f0102b6d:	eb 29                	jmp    f0102b98 <debuginfo_eip+0x1a3>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102b6f:	83 ec 04             	sub    $0x4,%esp
f0102b72:	68 4d 48 10 f0       	push   $0xf010484d
f0102b77:	6a 7f                	push   $0x7f
f0102b79:	68 5a 48 10 f0       	push   $0xf010485a
f0102b7e:	e8 08 d5 ff ff       	call   f010008b <_panic>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102b83:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102b86:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b89:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102b8c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102b8f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102b92:	eb 87                	jmp    f0102b1b <debuginfo_eip+0x126>
f0102b94:	4a                   	dec    %edx
f0102b95:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102b98:	39 d6                	cmp    %edx,%esi
f0102b9a:	7f 34                	jg     f0102bd0 <debuginfo_eip+0x1db>
	       && stabs[lline].n_type != N_SOL
f0102b9c:	8a 08                	mov    (%eax),%cl
f0102b9e:	80 f9 84             	cmp    $0x84,%cl
f0102ba1:	74 0b                	je     f0102bae <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102ba3:	80 f9 64             	cmp    $0x64,%cl
f0102ba6:	75 ec                	jne    f0102b94 <debuginfo_eip+0x19f>
f0102ba8:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0102bac:	74 e6                	je     f0102b94 <debuginfo_eip+0x19f>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102bae:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0102bb1:	01 c2                	add    %eax,%edx
f0102bb3:	8b 14 95 78 4a 10 f0 	mov    -0xfefb588(,%edx,4),%edx
f0102bba:	b8 8c cd 10 f0       	mov    $0xf010cd8c,%eax
f0102bbf:	2d dd af 10 f0       	sub    $0xf010afdd,%eax
f0102bc4:	39 c2                	cmp    %eax,%edx
f0102bc6:	73 08                	jae    f0102bd0 <debuginfo_eip+0x1db>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102bc8:	81 c2 dd af 10 f0    	add    $0xf010afdd,%edx
f0102bce:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102bd0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102bd3:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0102bd6:	39 f2                	cmp    %esi,%edx
f0102bd8:	7d 46                	jge    f0102c20 <debuginfo_eip+0x22b>
		for (lline = lfun + 1;
f0102bda:	42                   	inc    %edx
f0102bdb:	89 d0                	mov    %edx,%eax
f0102bdd:	8d 0c 12             	lea    (%edx,%edx,1),%ecx
f0102be0:	01 ca                	add    %ecx,%edx
f0102be2:	8d 14 95 7c 4a 10 f0 	lea    -0xfefb584(,%edx,4),%edx
f0102be9:	eb 03                	jmp    f0102bee <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102beb:	ff 43 14             	incl   0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102bee:	39 c6                	cmp    %eax,%esi
f0102bf0:	7e 3b                	jle    f0102c2d <debuginfo_eip+0x238>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102bf2:	8a 0a                	mov    (%edx),%cl
f0102bf4:	40                   	inc    %eax
f0102bf5:	83 c2 0c             	add    $0xc,%edx
f0102bf8:	80 f9 a0             	cmp    $0xa0,%cl
f0102bfb:	74 ee                	je     f0102beb <debuginfo_eip+0x1f6>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102bfd:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c02:	eb 21                	jmp    f0102c25 <debuginfo_eip+0x230>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102c04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102c09:	eb 1a                	jmp    f0102c25 <debuginfo_eip+0x230>
f0102c0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102c10:	eb 13                	jmp    f0102c25 <debuginfo_eip+0x230>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102c12:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102c17:	eb 0c                	jmp    f0102c25 <debuginfo_eip+0x230>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
  stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); 
  if(lline > rline) {
    return -1;
f0102c19:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102c1e:	eb 05                	jmp    f0102c25 <debuginfo_eip+0x230>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102c20:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102c25:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102c28:	5b                   	pop    %ebx
f0102c29:	5e                   	pop    %esi
f0102c2a:	5f                   	pop    %edi
f0102c2b:	5d                   	pop    %ebp
f0102c2c:	c3                   	ret    
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102c2d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c32:	eb f1                	jmp    f0102c25 <debuginfo_eip+0x230>

f0102c34 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102c34:	55                   	push   %ebp
f0102c35:	89 e5                	mov    %esp,%ebp
f0102c37:	57                   	push   %edi
f0102c38:	56                   	push   %esi
f0102c39:	53                   	push   %ebx
f0102c3a:	83 ec 1c             	sub    $0x1c,%esp
f0102c3d:	89 c7                	mov    %eax,%edi
f0102c3f:	89 d6                	mov    %edx,%esi
f0102c41:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c44:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102c47:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102c4a:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102c4d:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102c50:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102c55:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102c58:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102c5b:	39 d3                	cmp    %edx,%ebx
f0102c5d:	72 05                	jb     f0102c64 <printnum+0x30>
f0102c5f:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102c62:	77 78                	ja     f0102cdc <printnum+0xa8>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102c64:	83 ec 0c             	sub    $0xc,%esp
f0102c67:	ff 75 18             	pushl  0x18(%ebp)
f0102c6a:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c6d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102c70:	53                   	push   %ebx
f0102c71:	ff 75 10             	pushl  0x10(%ebp)
f0102c74:	83 ec 08             	sub    $0x8,%esp
f0102c77:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102c7a:	ff 75 e0             	pushl  -0x20(%ebp)
f0102c7d:	ff 75 dc             	pushl  -0x24(%ebp)
f0102c80:	ff 75 d8             	pushl  -0x28(%ebp)
f0102c83:	e8 94 09 00 00       	call   f010361c <__udivdi3>
f0102c88:	83 c4 18             	add    $0x18,%esp
f0102c8b:	52                   	push   %edx
f0102c8c:	50                   	push   %eax
f0102c8d:	89 f2                	mov    %esi,%edx
f0102c8f:	89 f8                	mov    %edi,%eax
f0102c91:	e8 9e ff ff ff       	call   f0102c34 <printnum>
f0102c96:	83 c4 20             	add    $0x20,%esp
f0102c99:	eb 11                	jmp    f0102cac <printnum+0x78>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102c9b:	83 ec 08             	sub    $0x8,%esp
f0102c9e:	56                   	push   %esi
f0102c9f:	ff 75 18             	pushl  0x18(%ebp)
f0102ca2:	ff d7                	call   *%edi
f0102ca4:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102ca7:	4b                   	dec    %ebx
f0102ca8:	85 db                	test   %ebx,%ebx
f0102caa:	7f ef                	jg     f0102c9b <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102cac:	83 ec 08             	sub    $0x8,%esp
f0102caf:	56                   	push   %esi
f0102cb0:	83 ec 04             	sub    $0x4,%esp
f0102cb3:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102cb6:	ff 75 e0             	pushl  -0x20(%ebp)
f0102cb9:	ff 75 dc             	pushl  -0x24(%ebp)
f0102cbc:	ff 75 d8             	pushl  -0x28(%ebp)
f0102cbf:	e8 68 0a 00 00       	call   f010372c <__umoddi3>
f0102cc4:	83 c4 14             	add    $0x14,%esp
f0102cc7:	0f be 80 68 48 10 f0 	movsbl -0xfefb798(%eax),%eax
f0102cce:	50                   	push   %eax
f0102ccf:	ff d7                	call   *%edi
}
f0102cd1:	83 c4 10             	add    $0x10,%esp
f0102cd4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102cd7:	5b                   	pop    %ebx
f0102cd8:	5e                   	pop    %esi
f0102cd9:	5f                   	pop    %edi
f0102cda:	5d                   	pop    %ebp
f0102cdb:	c3                   	ret    
f0102cdc:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0102cdf:	eb c6                	jmp    f0102ca7 <printnum+0x73>

f0102ce1 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102ce1:	55                   	push   %ebp
f0102ce2:	89 e5                	mov    %esp,%ebp
f0102ce4:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102ce7:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f0102cea:	8b 10                	mov    (%eax),%edx
f0102cec:	3b 50 04             	cmp    0x4(%eax),%edx
f0102cef:	73 0a                	jae    f0102cfb <sprintputch+0x1a>
		*b->buf++ = ch;
f0102cf1:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102cf4:	89 08                	mov    %ecx,(%eax)
f0102cf6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cf9:	88 02                	mov    %al,(%edx)
}
f0102cfb:	5d                   	pop    %ebp
f0102cfc:	c3                   	ret    

f0102cfd <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102cfd:	55                   	push   %ebp
f0102cfe:	89 e5                	mov    %esp,%ebp
f0102d00:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102d03:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102d06:	50                   	push   %eax
f0102d07:	ff 75 10             	pushl  0x10(%ebp)
f0102d0a:	ff 75 0c             	pushl  0xc(%ebp)
f0102d0d:	ff 75 08             	pushl  0x8(%ebp)
f0102d10:	e8 05 00 00 00       	call   f0102d1a <vprintfmt>
	va_end(ap);
}
f0102d15:	83 c4 10             	add    $0x10,%esp
f0102d18:	c9                   	leave  
f0102d19:	c3                   	ret    

f0102d1a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102d1a:	55                   	push   %ebp
f0102d1b:	89 e5                	mov    %esp,%ebp
f0102d1d:	57                   	push   %edi
f0102d1e:	56                   	push   %esi
f0102d1f:	53                   	push   %ebx
f0102d20:	83 ec 2c             	sub    $0x2c,%esp
f0102d23:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d26:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d29:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102d2c:	e9 ae 03 00 00       	jmp    f01030df <vprintfmt+0x3c5>
f0102d31:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102d35:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102d3c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102d43:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102d4a:	b9 00 00 00 00       	mov    $0x0,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d4f:	8d 47 01             	lea    0x1(%edi),%eax
f0102d52:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102d55:	8a 17                	mov    (%edi),%dl
f0102d57:	8d 42 dd             	lea    -0x23(%edx),%eax
f0102d5a:	3c 55                	cmp    $0x55,%al
f0102d5c:	0f 87 fe 03 00 00    	ja     f0103160 <vprintfmt+0x446>
f0102d62:	0f b6 c0             	movzbl %al,%eax
f0102d65:	ff 24 85 f4 48 10 f0 	jmp    *-0xfefb70c(,%eax,4)
f0102d6c:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102d6f:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0102d73:	eb da                	jmp    f0102d4f <vprintfmt+0x35>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d75:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102d78:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102d7c:	eb d1                	jmp    f0102d4f <vprintfmt+0x35>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102d7e:	0f b6 d2             	movzbl %dl,%edx
f0102d81:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102d84:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d89:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102d8c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102d8f:	01 c0                	add    %eax,%eax
f0102d91:	8d 44 02 d0          	lea    -0x30(%edx,%eax,1),%eax
				ch = *fmt;
f0102d95:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0102d98:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0102d9b:	83 f9 09             	cmp    $0x9,%ecx
f0102d9e:	77 52                	ja     f0102df2 <vprintfmt+0xd8>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102da0:	47                   	inc    %edi
				precision = precision * 10 + ch - '0';
f0102da1:	eb e9                	jmp    f0102d8c <vprintfmt+0x72>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102da3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102da6:	8b 00                	mov    (%eax),%eax
f0102da8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102dab:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dae:	8d 40 04             	lea    0x4(%eax),%eax
f0102db1:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102db4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0102db7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102dbb:	79 92                	jns    f0102d4f <vprintfmt+0x35>
				width = precision, precision = -1;
f0102dbd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102dc0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102dc3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102dca:	eb 83                	jmp    f0102d4f <vprintfmt+0x35>
f0102dcc:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102dd0:	78 08                	js     f0102dda <vprintfmt+0xc0>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dd2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dd5:	e9 75 ff ff ff       	jmp    f0102d4f <vprintfmt+0x35>
f0102dda:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102de1:	eb ef                	jmp    f0102dd2 <vprintfmt+0xb8>
f0102de3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102de6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102ded:	e9 5d ff ff ff       	jmp    f0102d4f <vprintfmt+0x35>
f0102df2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102df5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102df8:	eb bd                	jmp    f0102db7 <vprintfmt+0x9d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102dfa:	41                   	inc    %ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dfb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102dfe:	e9 4c ff ff ff       	jmp    f0102d4f <vprintfmt+0x35>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102e03:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e06:	8d 78 04             	lea    0x4(%eax),%edi
f0102e09:	83 ec 08             	sub    $0x8,%esp
f0102e0c:	53                   	push   %ebx
f0102e0d:	ff 30                	pushl  (%eax)
f0102e0f:	ff d6                	call   *%esi
			break;
f0102e11:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102e14:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0102e17:	e9 c0 02 00 00       	jmp    f01030dc <vprintfmt+0x3c2>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102e1c:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e1f:	8d 78 04             	lea    0x4(%eax),%edi
f0102e22:	8b 00                	mov    (%eax),%eax
f0102e24:	85 c0                	test   %eax,%eax
f0102e26:	78 2a                	js     f0102e52 <vprintfmt+0x138>
f0102e28:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102e2a:	83 f8 06             	cmp    $0x6,%eax
f0102e2d:	7f 27                	jg     f0102e56 <vprintfmt+0x13c>
f0102e2f:	8b 04 85 4c 4a 10 f0 	mov    -0xfefb5b4(,%eax,4),%eax
f0102e36:	85 c0                	test   %eax,%eax
f0102e38:	74 1c                	je     f0102e56 <vprintfmt+0x13c>
				printfmt(putch, putdat, "error %d", err);
			else
				printfmt(putch, putdat, "%s", p);
f0102e3a:	50                   	push   %eax
f0102e3b:	68 98 45 10 f0       	push   $0xf0104598
f0102e40:	53                   	push   %ebx
f0102e41:	56                   	push   %esi
f0102e42:	e8 b6 fe ff ff       	call   f0102cfd <printfmt>
f0102e47:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102e4a:	89 7d 14             	mov    %edi,0x14(%ebp)
f0102e4d:	e9 8a 02 00 00       	jmp    f01030dc <vprintfmt+0x3c2>
f0102e52:	f7 d8                	neg    %eax
f0102e54:	eb d2                	jmp    f0102e28 <vprintfmt+0x10e>
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102e56:	52                   	push   %edx
f0102e57:	68 80 48 10 f0       	push   $0xf0104880
f0102e5c:	53                   	push   %ebx
f0102e5d:	56                   	push   %esi
f0102e5e:	e8 9a fe ff ff       	call   f0102cfd <printfmt>
f0102e63:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102e66:	89 7d 14             	mov    %edi,0x14(%ebp)
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102e69:	e9 6e 02 00 00       	jmp    f01030dc <vprintfmt+0x3c2>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102e6e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e71:	83 c0 04             	add    $0x4,%eax
f0102e74:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102e77:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e7a:	8b 38                	mov    (%eax),%edi
f0102e7c:	85 ff                	test   %edi,%edi
f0102e7e:	74 39                	je     f0102eb9 <vprintfmt+0x19f>
				p = "(null)";
			if (width > 0 && padc != '-')
f0102e80:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102e84:	0f 8e a9 00 00 00    	jle    f0102f33 <vprintfmt+0x219>
f0102e8a:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102e8e:	0f 84 a7 00 00 00    	je     f0102f3b <vprintfmt+0x221>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102e94:	83 ec 08             	sub    $0x8,%esp
f0102e97:	ff 75 d0             	pushl  -0x30(%ebp)
f0102e9a:	57                   	push   %edi
f0102e9b:	e8 56 04 00 00       	call   f01032f6 <strnlen>
f0102ea0:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102ea3:	29 c1                	sub    %eax,%ecx
f0102ea5:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102ea8:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102eab:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102eaf:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102eb2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102eb5:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102eb7:	eb 14                	jmp    f0102ecd <vprintfmt+0x1b3>
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
f0102eb9:	bf 79 48 10 f0       	mov    $0xf0104879,%edi
f0102ebe:	eb c0                	jmp    f0102e80 <vprintfmt+0x166>
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
f0102ec0:	83 ec 08             	sub    $0x8,%esp
f0102ec3:	53                   	push   %ebx
f0102ec4:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ec7:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102ec9:	4f                   	dec    %edi
f0102eca:	83 c4 10             	add    $0x10,%esp
f0102ecd:	85 ff                	test   %edi,%edi
f0102ecf:	7f ef                	jg     f0102ec0 <vprintfmt+0x1a6>
f0102ed1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102ed4:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102ed7:	89 c8                	mov    %ecx,%eax
f0102ed9:	85 c9                	test   %ecx,%ecx
f0102edb:	78 10                	js     f0102eed <vprintfmt+0x1d3>
f0102edd:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102ee0:	29 c1                	sub    %eax,%ecx
f0102ee2:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102ee5:	89 75 08             	mov    %esi,0x8(%ebp)
f0102ee8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102eeb:	eb 15                	jmp    f0102f02 <vprintfmt+0x1e8>
f0102eed:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ef2:	eb e9                	jmp    f0102edd <vprintfmt+0x1c3>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
f0102ef4:	83 ec 08             	sub    $0x8,%esp
f0102ef7:	53                   	push   %ebx
f0102ef8:	52                   	push   %edx
f0102ef9:	ff 55 08             	call   *0x8(%ebp)
f0102efc:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102eff:	ff 4d e0             	decl   -0x20(%ebp)
f0102f02:	47                   	inc    %edi
f0102f03:	8a 47 ff             	mov    -0x1(%edi),%al
f0102f06:	0f be d0             	movsbl %al,%edx
f0102f09:	85 d2                	test   %edx,%edx
f0102f0b:	74 59                	je     f0102f66 <vprintfmt+0x24c>
f0102f0d:	85 f6                	test   %esi,%esi
f0102f0f:	78 03                	js     f0102f14 <vprintfmt+0x1fa>
f0102f11:	4e                   	dec    %esi
f0102f12:	78 2f                	js     f0102f43 <vprintfmt+0x229>
				if (altflag && (ch < ' ' || ch > '~'))
f0102f14:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102f18:	74 da                	je     f0102ef4 <vprintfmt+0x1da>
f0102f1a:	0f be c0             	movsbl %al,%eax
f0102f1d:	83 e8 20             	sub    $0x20,%eax
f0102f20:	83 f8 5e             	cmp    $0x5e,%eax
f0102f23:	76 cf                	jbe    f0102ef4 <vprintfmt+0x1da>
					putch('?', putdat);
f0102f25:	83 ec 08             	sub    $0x8,%esp
f0102f28:	53                   	push   %ebx
f0102f29:	6a 3f                	push   $0x3f
f0102f2b:	ff 55 08             	call   *0x8(%ebp)
f0102f2e:	83 c4 10             	add    $0x10,%esp
f0102f31:	eb cc                	jmp    f0102eff <vprintfmt+0x1e5>
f0102f33:	89 75 08             	mov    %esi,0x8(%ebp)
f0102f36:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102f39:	eb c7                	jmp    f0102f02 <vprintfmt+0x1e8>
f0102f3b:	89 75 08             	mov    %esi,0x8(%ebp)
f0102f3e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102f41:	eb bf                	jmp    f0102f02 <vprintfmt+0x1e8>
f0102f43:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f46:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102f49:	eb 0c                	jmp    f0102f57 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102f4b:	83 ec 08             	sub    $0x8,%esp
f0102f4e:	53                   	push   %ebx
f0102f4f:	6a 20                	push   $0x20
f0102f51:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102f53:	4f                   	dec    %edi
f0102f54:	83 c4 10             	add    $0x10,%esp
f0102f57:	85 ff                	test   %edi,%edi
f0102f59:	7f f0                	jg     f0102f4b <vprintfmt+0x231>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102f5b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102f5e:	89 45 14             	mov    %eax,0x14(%ebp)
f0102f61:	e9 76 01 00 00       	jmp    f01030dc <vprintfmt+0x3c2>
f0102f66:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0102f69:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f6c:	eb e9                	jmp    f0102f57 <vprintfmt+0x23d>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102f6e:	83 f9 01             	cmp    $0x1,%ecx
f0102f71:	7f 1f                	jg     f0102f92 <vprintfmt+0x278>
		return va_arg(*ap, long long);
	else if (lflag)
f0102f73:	85 c9                	test   %ecx,%ecx
f0102f75:	75 48                	jne    f0102fbf <vprintfmt+0x2a5>
		return va_arg(*ap, long);
	else
		return va_arg(*ap, int);
f0102f77:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f7a:	8b 00                	mov    (%eax),%eax
f0102f7c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f7f:	89 c1                	mov    %eax,%ecx
f0102f81:	c1 f9 1f             	sar    $0x1f,%ecx
f0102f84:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102f87:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f8a:	8d 40 04             	lea    0x4(%eax),%eax
f0102f8d:	89 45 14             	mov    %eax,0x14(%ebp)
f0102f90:	eb 17                	jmp    f0102fa9 <vprintfmt+0x28f>
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, long long);
f0102f92:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f95:	8b 50 04             	mov    0x4(%eax),%edx
f0102f98:	8b 00                	mov    (%eax),%eax
f0102f9a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f9d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102fa0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fa3:	8d 40 08             	lea    0x8(%eax),%eax
f0102fa6:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102fa9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fac:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
f0102faf:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102fb3:	78 25                	js     f0102fda <vprintfmt+0x2c0>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102fb5:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102fba:	e9 03 01 00 00       	jmp    f01030c2 <vprintfmt+0x3a8>
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, long long);
	else if (lflag)
		return va_arg(*ap, long);
f0102fbf:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fc2:	8b 00                	mov    (%eax),%eax
f0102fc4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102fc7:	89 c1                	mov    %eax,%ecx
f0102fc9:	c1 f9 1f             	sar    $0x1f,%ecx
f0102fcc:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102fcf:	8b 45 14             	mov    0x14(%ebp),%eax
f0102fd2:	8d 40 04             	lea    0x4(%eax),%eax
f0102fd5:	89 45 14             	mov    %eax,0x14(%ebp)
f0102fd8:	eb cf                	jmp    f0102fa9 <vprintfmt+0x28f>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f0102fda:	83 ec 08             	sub    $0x8,%esp
f0102fdd:	53                   	push   %ebx
f0102fde:	6a 2d                	push   $0x2d
f0102fe0:	ff d6                	call   *%esi
				num = -(long long) num;
f0102fe2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102fe5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102fe8:	f7 da                	neg    %edx
f0102fea:	83 d1 00             	adc    $0x0,%ecx
f0102fed:	f7 d9                	neg    %ecx
f0102fef:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102ff2:	b8 0a 00 00 00       	mov    $0xa,%eax
f0102ff7:	e9 c6 00 00 00       	jmp    f01030c2 <vprintfmt+0x3a8>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102ffc:	83 f9 01             	cmp    $0x1,%ecx
f0102fff:	7f 1e                	jg     f010301f <vprintfmt+0x305>
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103001:	85 c9                	test   %ecx,%ecx
f0103003:	75 32                	jne    f0103037 <vprintfmt+0x31d>
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103005:	8b 45 14             	mov    0x14(%ebp),%eax
f0103008:	8b 10                	mov    (%eax),%edx
f010300a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010300f:	8d 40 04             	lea    0x4(%eax),%eax
f0103012:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103015:	b8 0a 00 00 00       	mov    $0xa,%eax
f010301a:	e9 a3 00 00 00       	jmp    f01030c2 <vprintfmt+0x3a8>
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
f010301f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103022:	8b 10                	mov    (%eax),%edx
f0103024:	8b 48 04             	mov    0x4(%eax),%ecx
f0103027:	8d 40 08             	lea    0x8(%eax),%eax
f010302a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010302d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103032:	e9 8b 00 00 00       	jmp    f01030c2 <vprintfmt+0x3a8>
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
f0103037:	8b 45 14             	mov    0x14(%ebp),%eax
f010303a:	8b 10                	mov    (%eax),%edx
f010303c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103041:	8d 40 04             	lea    0x4(%eax),%eax
f0103044:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0103047:	b8 0a 00 00 00       	mov    $0xa,%eax
f010304c:	eb 74                	jmp    f01030c2 <vprintfmt+0x3a8>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010304e:	83 f9 01             	cmp    $0x1,%ecx
f0103051:	7f 1b                	jg     f010306e <vprintfmt+0x354>
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103053:	85 c9                	test   %ecx,%ecx
f0103055:	75 2c                	jne    f0103083 <vprintfmt+0x369>
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0103057:	8b 45 14             	mov    0x14(%ebp),%eax
f010305a:	8b 10                	mov    (%eax),%edx
f010305c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103061:	8d 40 04             	lea    0x4(%eax),%eax
f0103064:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
			base = 8;
f0103067:	b8 08 00 00 00       	mov    $0x8,%eax
f010306c:	eb 54                	jmp    f01030c2 <vprintfmt+0x3a8>
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
f010306e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103071:	8b 10                	mov    (%eax),%edx
f0103073:	8b 48 04             	mov    0x4(%eax),%ecx
f0103076:	8d 40 08             	lea    0x8(%eax),%eax
f0103079:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
			base = 8;
f010307c:	b8 08 00 00 00       	mov    $0x8,%eax
f0103081:	eb 3f                	jmp    f01030c2 <vprintfmt+0x3a8>
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
f0103083:	8b 45 14             	mov    0x14(%ebp),%eax
f0103086:	8b 10                	mov    (%eax),%edx
f0103088:	b9 00 00 00 00       	mov    $0x0,%ecx
f010308d:	8d 40 04             	lea    0x4(%eax),%eax
f0103090:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
			base = 8;
f0103093:	b8 08 00 00 00       	mov    $0x8,%eax
f0103098:	eb 28                	jmp    f01030c2 <vprintfmt+0x3a8>
			goto number;

		// pointer
		case 'p':
			putch('0', putdat);
f010309a:	83 ec 08             	sub    $0x8,%esp
f010309d:	53                   	push   %ebx
f010309e:	6a 30                	push   $0x30
f01030a0:	ff d6                	call   *%esi
			putch('x', putdat);
f01030a2:	83 c4 08             	add    $0x8,%esp
f01030a5:	53                   	push   %ebx
f01030a6:	6a 78                	push   $0x78
f01030a8:	ff d6                	call   *%esi
			num = (unsigned long long)
f01030aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01030ad:	8b 10                	mov    (%eax),%edx
f01030af:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01030b4:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01030b7:	8d 40 04             	lea    0x4(%eax),%eax
f01030ba:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01030bd:	b8 10 00 00 00       	mov    $0x10,%eax
		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
		number:
			printnum(putch, putdat, num, base, width, padc);
f01030c2:	83 ec 0c             	sub    $0xc,%esp
f01030c5:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01030c9:	57                   	push   %edi
f01030ca:	ff 75 e0             	pushl  -0x20(%ebp)
f01030cd:	50                   	push   %eax
f01030ce:	51                   	push   %ecx
f01030cf:	52                   	push   %edx
f01030d0:	89 da                	mov    %ebx,%edx
f01030d2:	89 f0                	mov    %esi,%eax
f01030d4:	e8 5b fb ff ff       	call   f0102c34 <printnum>
			break;
f01030d9:	83 c4 20             	add    $0x20,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f01030dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01030df:	47                   	inc    %edi
f01030e0:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01030e4:	83 f8 25             	cmp    $0x25,%eax
f01030e7:	0f 84 44 fc ff ff    	je     f0102d31 <vprintfmt+0x17>
			if (ch == '\0')
f01030ed:	85 c0                	test   %eax,%eax
f01030ef:	0f 84 89 00 00 00    	je     f010317e <vprintfmt+0x464>
				return;
			putch(ch, putdat);
f01030f5:	83 ec 08             	sub    $0x8,%esp
f01030f8:	53                   	push   %ebx
f01030f9:	50                   	push   %eax
f01030fa:	ff d6                	call   *%esi
f01030fc:	83 c4 10             	add    $0x10,%esp
f01030ff:	eb de                	jmp    f01030df <vprintfmt+0x3c5>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103101:	83 f9 01             	cmp    $0x1,%ecx
f0103104:	7f 1b                	jg     f0103121 <vprintfmt+0x407>
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0103106:	85 c9                	test   %ecx,%ecx
f0103108:	75 2c                	jne    f0103136 <vprintfmt+0x41c>
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010310a:	8b 45 14             	mov    0x14(%ebp),%eax
f010310d:	8b 10                	mov    (%eax),%edx
f010310f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103114:	8d 40 04             	lea    0x4(%eax),%eax
f0103117:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010311a:	b8 10 00 00 00       	mov    $0x10,%eax
f010311f:	eb a1                	jmp    f01030c2 <vprintfmt+0x3a8>
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
f0103121:	8b 45 14             	mov    0x14(%ebp),%eax
f0103124:	8b 10                	mov    (%eax),%edx
f0103126:	8b 48 04             	mov    0x4(%eax),%ecx
f0103129:	8d 40 08             	lea    0x8(%eax),%eax
f010312c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010312f:	b8 10 00 00 00       	mov    $0x10,%eax
f0103134:	eb 8c                	jmp    f01030c2 <vprintfmt+0x3a8>
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
f0103136:	8b 45 14             	mov    0x14(%ebp),%eax
f0103139:	8b 10                	mov    (%eax),%edx
f010313b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103140:	8d 40 04             	lea    0x4(%eax),%eax
f0103143:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0103146:	b8 10 00 00 00       	mov    $0x10,%eax
f010314b:	e9 72 ff ff ff       	jmp    f01030c2 <vprintfmt+0x3a8>
			printnum(putch, putdat, num, base, width, padc);
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103150:	83 ec 08             	sub    $0x8,%esp
f0103153:	53                   	push   %ebx
f0103154:	6a 25                	push   $0x25
f0103156:	ff d6                	call   *%esi
			break;
f0103158:	83 c4 10             	add    $0x10,%esp
f010315b:	e9 7c ff ff ff       	jmp    f01030dc <vprintfmt+0x3c2>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103160:	83 ec 08             	sub    $0x8,%esp
f0103163:	53                   	push   %ebx
f0103164:	6a 25                	push   $0x25
f0103166:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103168:	83 c4 10             	add    $0x10,%esp
f010316b:	89 f8                	mov    %edi,%eax
f010316d:	eb 01                	jmp    f0103170 <vprintfmt+0x456>
f010316f:	48                   	dec    %eax
f0103170:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103174:	75 f9                	jne    f010316f <vprintfmt+0x455>
f0103176:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103179:	e9 5e ff ff ff       	jmp    f01030dc <vprintfmt+0x3c2>
				/* do nothing */;
			break;
		}
	}
}
f010317e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103181:	5b                   	pop    %ebx
f0103182:	5e                   	pop    %esi
f0103183:	5f                   	pop    %edi
f0103184:	5d                   	pop    %ebp
f0103185:	c3                   	ret    

f0103186 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103186:	55                   	push   %ebp
f0103187:	89 e5                	mov    %esp,%ebp
f0103189:	83 ec 18             	sub    $0x18,%esp
f010318c:	8b 45 08             	mov    0x8(%ebp),%eax
f010318f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103192:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103195:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103199:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010319c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01031a3:	85 c0                	test   %eax,%eax
f01031a5:	74 26                	je     f01031cd <vsnprintf+0x47>
f01031a7:	85 d2                	test   %edx,%edx
f01031a9:	7e 29                	jle    f01031d4 <vsnprintf+0x4e>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01031ab:	ff 75 14             	pushl  0x14(%ebp)
f01031ae:	ff 75 10             	pushl  0x10(%ebp)
f01031b1:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01031b4:	50                   	push   %eax
f01031b5:	68 e1 2c 10 f0       	push   $0xf0102ce1
f01031ba:	e8 5b fb ff ff       	call   f0102d1a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01031bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01031c2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01031c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01031c8:	83 c4 10             	add    $0x10,%esp
}
f01031cb:	c9                   	leave  
f01031cc:	c3                   	ret    
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01031cd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01031d2:	eb f7                	jmp    f01031cb <vsnprintf+0x45>
f01031d4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01031d9:	eb f0                	jmp    f01031cb <vsnprintf+0x45>

f01031db <snprintf>:
	return b.cnt;
}

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01031db:	55                   	push   %ebp
f01031dc:	89 e5                	mov    %esp,%ebp
f01031de:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01031e1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01031e4:	50                   	push   %eax
f01031e5:	ff 75 10             	pushl  0x10(%ebp)
f01031e8:	ff 75 0c             	pushl  0xc(%ebp)
f01031eb:	ff 75 08             	pushl  0x8(%ebp)
f01031ee:	e8 93 ff ff ff       	call   f0103186 <vsnprintf>
	va_end(ap);

	return rc;
}
f01031f3:	c9                   	leave  
f01031f4:	c3                   	ret    
f01031f5:	00 00                	add    %al,(%eax)
	...

f01031f8 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01031f8:	55                   	push   %ebp
f01031f9:	89 e5                	mov    %esp,%ebp
f01031fb:	57                   	push   %edi
f01031fc:	56                   	push   %esi
f01031fd:	53                   	push   %ebx
f01031fe:	83 ec 0c             	sub    $0xc,%esp
f0103201:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103204:	85 c0                	test   %eax,%eax
f0103206:	74 11                	je     f0103219 <readline+0x21>
		cprintf("%s", prompt);
f0103208:	83 ec 08             	sub    $0x8,%esp
f010320b:	50                   	push   %eax
f010320c:	68 98 45 10 f0       	push   $0xf0104598
f0103211:	e8 db f6 ff ff       	call   f01028f1 <cprintf>
f0103216:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103219:	83 ec 0c             	sub    $0xc,%esp
f010321c:	6a 00                	push   $0x0
f010321e:	e8 d5 d3 ff ff       	call   f01005f8 <iscons>
f0103223:	89 c7                	mov    %eax,%edi
f0103225:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103228:	be 00 00 00 00       	mov    $0x0,%esi
f010322d:	eb 6f                	jmp    f010329e <readline+0xa6>
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f010322f:	83 ec 08             	sub    $0x8,%esp
f0103232:	50                   	push   %eax
f0103233:	68 68 4a 10 f0       	push   $0xf0104a68
f0103238:	e8 b4 f6 ff ff       	call   f01028f1 <cprintf>
			return NULL;
f010323d:	83 c4 10             	add    $0x10,%esp
f0103240:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103245:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103248:	5b                   	pop    %ebx
f0103249:	5e                   	pop    %esi
f010324a:	5f                   	pop    %edi
f010324b:	5d                   	pop    %ebp
f010324c:	c3                   	ret    
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
			if (echoing)
				cputchar('\b');
f010324d:	83 ec 0c             	sub    $0xc,%esp
f0103250:	6a 08                	push   $0x8
f0103252:	e8 80 d3 ff ff       	call   f01005d7 <cputchar>
f0103257:	83 c4 10             	add    $0x10,%esp
f010325a:	eb 41                	jmp    f010329d <readline+0xa5>
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
			if (echoing)
				cputchar(c);
f010325c:	83 ec 0c             	sub    $0xc,%esp
f010325f:	53                   	push   %ebx
f0103260:	e8 72 d3 ff ff       	call   f01005d7 <cputchar>
f0103265:	83 c4 10             	add    $0x10,%esp
f0103268:	eb 5a                	jmp    f01032c4 <readline+0xcc>
			buf[i++] = c;
		} else if (c == '\n' || c == '\r') {
f010326a:	83 fb 0a             	cmp    $0xa,%ebx
f010326d:	74 05                	je     f0103274 <readline+0x7c>
f010326f:	83 fb 0d             	cmp    $0xd,%ebx
f0103272:	75 2a                	jne    f010329e <readline+0xa6>
			if (echoing)
f0103274:	85 ff                	test   %edi,%edi
f0103276:	75 0e                	jne    f0103286 <readline+0x8e>
				cputchar('\n');
			buf[i] = 0;
f0103278:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010327f:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
f0103284:	eb bf                	jmp    f0103245 <readline+0x4d>
			if (echoing)
				cputchar(c);
			buf[i++] = c;
		} else if (c == '\n' || c == '\r') {
			if (echoing)
				cputchar('\n');
f0103286:	83 ec 0c             	sub    $0xc,%esp
f0103289:	6a 0a                	push   $0xa
f010328b:	e8 47 d3 ff ff       	call   f01005d7 <cputchar>
f0103290:	83 c4 10             	add    $0x10,%esp
f0103293:	eb e3                	jmp    f0103278 <readline+0x80>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103295:	85 f6                	test   %esi,%esi
f0103297:	7e 3c                	jle    f01032d5 <readline+0xdd>
			if (echoing)
f0103299:	85 ff                	test   %edi,%edi
f010329b:	75 b0                	jne    f010324d <readline+0x55>
				cputchar('\b');
			i--;
f010329d:	4e                   	dec    %esi
		cprintf("%s", prompt);

	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010329e:	e8 44 d3 ff ff       	call   f01005e7 <getchar>
f01032a3:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01032a5:	85 c0                	test   %eax,%eax
f01032a7:	78 86                	js     f010322f <readline+0x37>
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01032a9:	83 f8 08             	cmp    $0x8,%eax
f01032ac:	74 21                	je     f01032cf <readline+0xd7>
f01032ae:	83 f8 7f             	cmp    $0x7f,%eax
f01032b1:	74 e2                	je     f0103295 <readline+0x9d>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f01032b3:	83 f8 1f             	cmp    $0x1f,%eax
f01032b6:	7e b2                	jle    f010326a <readline+0x72>
f01032b8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01032be:	7f aa                	jg     f010326a <readline+0x72>
			if (echoing)
f01032c0:	85 ff                	test   %edi,%edi
f01032c2:	75 98                	jne    f010325c <readline+0x64>
				cputchar(c);
			buf[i++] = c;
f01032c4:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01032ca:	8d 76 01             	lea    0x1(%esi),%esi
f01032cd:	eb cf                	jmp    f010329e <readline+0xa6>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
			return NULL;
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01032cf:	85 f6                	test   %esi,%esi
f01032d1:	7f c6                	jg     f0103299 <readline+0xa1>
f01032d3:	eb c9                	jmp    f010329e <readline+0xa6>
			if (echoing)
				cputchar('\b');
			i--;
		} else if (c >= ' ' && i < BUFLEN-1) {
f01032d5:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01032db:	7e e3                	jle    f01032c0 <readline+0xc8>
f01032dd:	eb bf                	jmp    f010329e <readline+0xa6>
	...

f01032e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01032e0:	55                   	push   %ebp
f01032e1:	89 e5                	mov    %esp,%ebp
f01032e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01032e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01032eb:	eb 01                	jmp    f01032ee <strlen+0xe>
		n++;
f01032ed:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01032ee:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01032f2:	75 f9                	jne    f01032ed <strlen+0xd>
		n++;
	return n;
}
f01032f4:	5d                   	pop    %ebp
f01032f5:	c3                   	ret    

f01032f6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01032f6:	55                   	push   %ebp
f01032f7:	89 e5                	mov    %esp,%ebp
f01032f9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032fc:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01032ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0103304:	eb 01                	jmp    f0103307 <strnlen+0x11>
		n++;
f0103306:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103307:	39 d0                	cmp    %edx,%eax
f0103309:	74 06                	je     f0103311 <strnlen+0x1b>
f010330b:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010330f:	75 f5                	jne    f0103306 <strnlen+0x10>
		n++;
	return n;
}
f0103311:	5d                   	pop    %ebp
f0103312:	c3                   	ret    

f0103313 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103313:	55                   	push   %ebp
f0103314:	89 e5                	mov    %esp,%ebp
f0103316:	53                   	push   %ebx
f0103317:	8b 45 08             	mov    0x8(%ebp),%eax
f010331a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010331d:	89 c2                	mov    %eax,%edx
f010331f:	42                   	inc    %edx
f0103320:	41                   	inc    %ecx
f0103321:	8a 59 ff             	mov    -0x1(%ecx),%bl
f0103324:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103327:	84 db                	test   %bl,%bl
f0103329:	75 f4                	jne    f010331f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010332b:	5b                   	pop    %ebx
f010332c:	5d                   	pop    %ebp
f010332d:	c3                   	ret    

f010332e <strcat>:

char *
strcat(char *dst, const char *src)
{
f010332e:	55                   	push   %ebp
f010332f:	89 e5                	mov    %esp,%ebp
f0103331:	53                   	push   %ebx
f0103332:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103335:	53                   	push   %ebx
f0103336:	e8 a5 ff ff ff       	call   f01032e0 <strlen>
f010333b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010333e:	ff 75 0c             	pushl  0xc(%ebp)
f0103341:	01 d8                	add    %ebx,%eax
f0103343:	50                   	push   %eax
f0103344:	e8 ca ff ff ff       	call   f0103313 <strcpy>
	return dst;
}
f0103349:	89 d8                	mov    %ebx,%eax
f010334b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010334e:	c9                   	leave  
f010334f:	c3                   	ret    

f0103350 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103350:	55                   	push   %ebp
f0103351:	89 e5                	mov    %esp,%ebp
f0103353:	56                   	push   %esi
f0103354:	53                   	push   %ebx
f0103355:	8b 75 08             	mov    0x8(%ebp),%esi
f0103358:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010335b:	89 f3                	mov    %esi,%ebx
f010335d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103360:	89 f2                	mov    %esi,%edx
f0103362:	eb 0c                	jmp    f0103370 <strncpy+0x20>
		*dst++ = *src;
f0103364:	42                   	inc    %edx
f0103365:	8a 01                	mov    (%ecx),%al
f0103367:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010336a:	80 39 01             	cmpb   $0x1,(%ecx)
f010336d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103370:	39 da                	cmp    %ebx,%edx
f0103372:	75 f0                	jne    f0103364 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103374:	89 f0                	mov    %esi,%eax
f0103376:	5b                   	pop    %ebx
f0103377:	5e                   	pop    %esi
f0103378:	5d                   	pop    %ebp
f0103379:	c3                   	ret    

f010337a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010337a:	55                   	push   %ebp
f010337b:	89 e5                	mov    %esp,%ebp
f010337d:	56                   	push   %esi
f010337e:	53                   	push   %ebx
f010337f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103382:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103385:	8b 45 10             	mov    0x10(%ebp),%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103388:	85 c0                	test   %eax,%eax
f010338a:	74 20                	je     f01033ac <strlcpy+0x32>
f010338c:	8d 5c 06 ff          	lea    -0x1(%esi,%eax,1),%ebx
f0103390:	89 f0                	mov    %esi,%eax
f0103392:	eb 05                	jmp    f0103399 <strlcpy+0x1f>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103394:	40                   	inc    %eax
f0103395:	42                   	inc    %edx
f0103396:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103399:	39 d8                	cmp    %ebx,%eax
f010339b:	74 06                	je     f01033a3 <strlcpy+0x29>
f010339d:	8a 0a                	mov    (%edx),%cl
f010339f:	84 c9                	test   %cl,%cl
f01033a1:	75 f1                	jne    f0103394 <strlcpy+0x1a>
			*dst++ = *src++;
		*dst = '\0';
f01033a3:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01033a6:	29 f0                	sub    %esi,%eax
}
f01033a8:	5b                   	pop    %ebx
f01033a9:	5e                   	pop    %esi
f01033aa:	5d                   	pop    %ebp
f01033ab:	c3                   	ret    
f01033ac:	89 f0                	mov    %esi,%eax
f01033ae:	eb f6                	jmp    f01033a6 <strlcpy+0x2c>

f01033b0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01033b0:	55                   	push   %ebp
f01033b1:	89 e5                	mov    %esp,%ebp
f01033b3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01033b6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01033b9:	eb 02                	jmp    f01033bd <strcmp+0xd>
		p++, q++;
f01033bb:	41                   	inc    %ecx
f01033bc:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01033bd:	8a 01                	mov    (%ecx),%al
f01033bf:	84 c0                	test   %al,%al
f01033c1:	74 04                	je     f01033c7 <strcmp+0x17>
f01033c3:	3a 02                	cmp    (%edx),%al
f01033c5:	74 f4                	je     f01033bb <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01033c7:	0f b6 c0             	movzbl %al,%eax
f01033ca:	0f b6 12             	movzbl (%edx),%edx
f01033cd:	29 d0                	sub    %edx,%eax
}
f01033cf:	5d                   	pop    %ebp
f01033d0:	c3                   	ret    

f01033d1 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01033d1:	55                   	push   %ebp
f01033d2:	89 e5                	mov    %esp,%ebp
f01033d4:	53                   	push   %ebx
f01033d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01033d8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01033db:	89 c3                	mov    %eax,%ebx
f01033dd:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01033e0:	eb 02                	jmp    f01033e4 <strncmp+0x13>
		n--, p++, q++;
f01033e2:	40                   	inc    %eax
f01033e3:	42                   	inc    %edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01033e4:	39 d8                	cmp    %ebx,%eax
f01033e6:	74 15                	je     f01033fd <strncmp+0x2c>
f01033e8:	8a 08                	mov    (%eax),%cl
f01033ea:	84 c9                	test   %cl,%cl
f01033ec:	74 04                	je     f01033f2 <strncmp+0x21>
f01033ee:	3a 0a                	cmp    (%edx),%cl
f01033f0:	74 f0                	je     f01033e2 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01033f2:	0f b6 00             	movzbl (%eax),%eax
f01033f5:	0f b6 12             	movzbl (%edx),%edx
f01033f8:	29 d0                	sub    %edx,%eax
}
f01033fa:	5b                   	pop    %ebx
f01033fb:	5d                   	pop    %ebp
f01033fc:	c3                   	ret    
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01033fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0103402:	eb f6                	jmp    f01033fa <strncmp+0x29>

f0103404 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103404:	55                   	push   %ebp
f0103405:	89 e5                	mov    %esp,%ebp
f0103407:	8b 45 08             	mov    0x8(%ebp),%eax
f010340a:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010340d:	8a 10                	mov    (%eax),%dl
f010340f:	84 d2                	test   %dl,%dl
f0103411:	74 07                	je     f010341a <strchr+0x16>
		if (*s == c)
f0103413:	38 ca                	cmp    %cl,%dl
f0103415:	74 08                	je     f010341f <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103417:	40                   	inc    %eax
f0103418:	eb f3                	jmp    f010340d <strchr+0x9>
		if (*s == c)
			return (char *) s;
	return 0;
f010341a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010341f:	5d                   	pop    %ebp
f0103420:	c3                   	ret    

f0103421 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103421:	55                   	push   %ebp
f0103422:	89 e5                	mov    %esp,%ebp
f0103424:	8b 45 08             	mov    0x8(%ebp),%eax
f0103427:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010342a:	8a 10                	mov    (%eax),%dl
f010342c:	84 d2                	test   %dl,%dl
f010342e:	74 07                	je     f0103437 <strfind+0x16>
		if (*s == c)
f0103430:	38 ca                	cmp    %cl,%dl
f0103432:	74 03                	je     f0103437 <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103434:	40                   	inc    %eax
f0103435:	eb f3                	jmp    f010342a <strfind+0x9>
		if (*s == c)
			break;
	return (char *) s;
}
f0103437:	5d                   	pop    %ebp
f0103438:	c3                   	ret    

f0103439 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103439:	55                   	push   %ebp
f010343a:	89 e5                	mov    %esp,%ebp
f010343c:	57                   	push   %edi
f010343d:	56                   	push   %esi
f010343e:	53                   	push   %ebx
f010343f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103442:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103445:	85 c9                	test   %ecx,%ecx
f0103447:	74 13                	je     f010345c <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103449:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010344f:	75 05                	jne    f0103456 <memset+0x1d>
f0103451:	f6 c1 03             	test   $0x3,%cl
f0103454:	74 0d                	je     f0103463 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103456:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103459:	fc                   	cld    
f010345a:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010345c:	89 f8                	mov    %edi,%eax
f010345e:	5b                   	pop    %ebx
f010345f:	5e                   	pop    %esi
f0103460:	5f                   	pop    %edi
f0103461:	5d                   	pop    %ebp
f0103462:	c3                   	ret    
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
f0103463:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103467:	89 d3                	mov    %edx,%ebx
f0103469:	c1 e3 08             	shl    $0x8,%ebx
f010346c:	89 d0                	mov    %edx,%eax
f010346e:	c1 e0 18             	shl    $0x18,%eax
f0103471:	89 d6                	mov    %edx,%esi
f0103473:	c1 e6 10             	shl    $0x10,%esi
f0103476:	09 f0                	or     %esi,%eax
f0103478:	09 c2                	or     %eax,%edx
f010347a:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010347c:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010347f:	89 d0                	mov    %edx,%eax
f0103481:	fc                   	cld    
f0103482:	f3 ab                	rep stos %eax,%es:(%edi)
f0103484:	eb d6                	jmp    f010345c <memset+0x23>

f0103486 <memmove>:
	return v;
}

void *
memmove(void *dst, const void *src, size_t n)
{
f0103486:	55                   	push   %ebp
f0103487:	89 e5                	mov    %esp,%ebp
f0103489:	57                   	push   %edi
f010348a:	56                   	push   %esi
f010348b:	8b 45 08             	mov    0x8(%ebp),%eax
f010348e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103491:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103494:	39 c6                	cmp    %eax,%esi
f0103496:	73 33                	jae    f01034cb <memmove+0x45>
f0103498:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010349b:	39 d0                	cmp    %edx,%eax
f010349d:	73 2c                	jae    f01034cb <memmove+0x45>
		s += n;
		d += n;
f010349f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01034a2:	89 d6                	mov    %edx,%esi
f01034a4:	09 fe                	or     %edi,%esi
f01034a6:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01034ac:	75 13                	jne    f01034c1 <memmove+0x3b>
f01034ae:	f6 c1 03             	test   $0x3,%cl
f01034b1:	75 0e                	jne    f01034c1 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01034b3:	83 ef 04             	sub    $0x4,%edi
f01034b6:	8d 72 fc             	lea    -0x4(%edx),%esi
f01034b9:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01034bc:	fd                   	std    
f01034bd:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01034bf:	eb 07                	jmp    f01034c8 <memmove+0x42>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01034c1:	4f                   	dec    %edi
f01034c2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01034c5:	fd                   	std    
f01034c6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01034c8:	fc                   	cld    
f01034c9:	eb 13                	jmp    f01034de <memmove+0x58>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01034cb:	89 f2                	mov    %esi,%edx
f01034cd:	09 c2                	or     %eax,%edx
f01034cf:	f6 c2 03             	test   $0x3,%dl
f01034d2:	75 05                	jne    f01034d9 <memmove+0x53>
f01034d4:	f6 c1 03             	test   $0x3,%cl
f01034d7:	74 09                	je     f01034e2 <memmove+0x5c>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01034d9:	89 c7                	mov    %eax,%edi
f01034db:	fc                   	cld    
f01034dc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01034de:	5e                   	pop    %esi
f01034df:	5f                   	pop    %edi
f01034e0:	5d                   	pop    %ebp
f01034e1:	c3                   	ret    
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01034e2:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01034e5:	89 c7                	mov    %eax,%edi
f01034e7:	fc                   	cld    
f01034e8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01034ea:	eb f2                	jmp    f01034de <memmove+0x58>

f01034ec <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01034ec:	55                   	push   %ebp
f01034ed:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01034ef:	ff 75 10             	pushl  0x10(%ebp)
f01034f2:	ff 75 0c             	pushl  0xc(%ebp)
f01034f5:	ff 75 08             	pushl  0x8(%ebp)
f01034f8:	e8 89 ff ff ff       	call   f0103486 <memmove>
}
f01034fd:	c9                   	leave  
f01034fe:	c3                   	ret    

f01034ff <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01034ff:	55                   	push   %ebp
f0103500:	89 e5                	mov    %esp,%ebp
f0103502:	56                   	push   %esi
f0103503:	53                   	push   %ebx
f0103504:	8b 45 08             	mov    0x8(%ebp),%eax
f0103507:	89 c6                	mov    %eax,%esi
f0103509:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;
f010350c:	8b 55 0c             	mov    0xc(%ebp),%edx

	while (n-- > 0) {
f010350f:	39 f0                	cmp    %esi,%eax
f0103511:	74 16                	je     f0103529 <memcmp+0x2a>
		if (*s1 != *s2)
f0103513:	8a 08                	mov    (%eax),%cl
f0103515:	8a 1a                	mov    (%edx),%bl
f0103517:	38 d9                	cmp    %bl,%cl
f0103519:	75 04                	jne    f010351f <memcmp+0x20>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010351b:	40                   	inc    %eax
f010351c:	42                   	inc    %edx
f010351d:	eb f0                	jmp    f010350f <memcmp+0x10>
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
f010351f:	0f b6 c1             	movzbl %cl,%eax
f0103522:	0f b6 db             	movzbl %bl,%ebx
f0103525:	29 d8                	sub    %ebx,%eax
f0103527:	eb 05                	jmp    f010352e <memcmp+0x2f>
		s1++, s2++;
	}

	return 0;
f0103529:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010352e:	5b                   	pop    %ebx
f010352f:	5e                   	pop    %esi
f0103530:	5d                   	pop    %ebp
f0103531:	c3                   	ret    

f0103532 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103532:	55                   	push   %ebp
f0103533:	89 e5                	mov    %esp,%ebp
f0103535:	8b 45 08             	mov    0x8(%ebp),%eax
f0103538:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010353b:	89 c2                	mov    %eax,%edx
f010353d:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103540:	39 d0                	cmp    %edx,%eax
f0103542:	73 07                	jae    f010354b <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103544:	38 08                	cmp    %cl,(%eax)
f0103546:	74 03                	je     f010354b <memfind+0x19>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103548:	40                   	inc    %eax
f0103549:	eb f5                	jmp    f0103540 <memfind+0xe>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010354b:	5d                   	pop    %ebp
f010354c:	c3                   	ret    

f010354d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010354d:	55                   	push   %ebp
f010354e:	89 e5                	mov    %esp,%ebp
f0103550:	57                   	push   %edi
f0103551:	56                   	push   %esi
f0103552:	53                   	push   %ebx
f0103553:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103556:	eb 01                	jmp    f0103559 <strtol+0xc>
		s++;
f0103558:	41                   	inc    %ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103559:	8a 01                	mov    (%ecx),%al
f010355b:	3c 20                	cmp    $0x20,%al
f010355d:	74 f9                	je     f0103558 <strtol+0xb>
f010355f:	3c 09                	cmp    $0x9,%al
f0103561:	74 f5                	je     f0103558 <strtol+0xb>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103563:	3c 2b                	cmp    $0x2b,%al
f0103565:	74 2b                	je     f0103592 <strtol+0x45>
		s++;
	else if (*s == '-')
f0103567:	3c 2d                	cmp    $0x2d,%al
f0103569:	74 2f                	je     f010359a <strtol+0x4d>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010356b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103570:	f7 45 10 ef ff ff ff 	testl  $0xffffffef,0x10(%ebp)
f0103577:	75 12                	jne    f010358b <strtol+0x3e>
f0103579:	80 39 30             	cmpb   $0x30,(%ecx)
f010357c:	74 24                	je     f01035a2 <strtol+0x55>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010357e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103582:	75 07                	jne    f010358b <strtol+0x3e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103584:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)
f010358b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103590:	eb 4e                	jmp    f01035e0 <strtol+0x93>
	while (*s == ' ' || *s == '\t')
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
f0103592:	41                   	inc    %ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103593:	bf 00 00 00 00       	mov    $0x0,%edi
f0103598:	eb d6                	jmp    f0103570 <strtol+0x23>

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
		s++, neg = 1;
f010359a:	41                   	inc    %ecx
f010359b:	bf 01 00 00 00       	mov    $0x1,%edi
f01035a0:	eb ce                	jmp    f0103570 <strtol+0x23>

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01035a2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01035a6:	74 10                	je     f01035b8 <strtol+0x6b>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01035a8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01035ac:	75 dd                	jne    f010358b <strtol+0x3e>
		s++, base = 8;
f01035ae:	41                   	inc    %ecx
f01035af:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f01035b6:	eb d3                	jmp    f010358b <strtol+0x3e>
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
f01035b8:	83 c1 02             	add    $0x2,%ecx
f01035bb:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f01035c2:	eb c7                	jmp    f010358b <strtol+0x3e>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01035c4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01035c7:	89 f3                	mov    %esi,%ebx
f01035c9:	80 fb 19             	cmp    $0x19,%bl
f01035cc:	77 24                	ja     f01035f2 <strtol+0xa5>
			dig = *s - 'a' + 10;
f01035ce:	0f be d2             	movsbl %dl,%edx
f01035d1:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01035d4:	3b 55 10             	cmp    0x10(%ebp),%edx
f01035d7:	7d 2b                	jge    f0103604 <strtol+0xb7>
			break;
		s++, val = (val * base) + dig;
f01035d9:	41                   	inc    %ecx
f01035da:	0f af 45 10          	imul   0x10(%ebp),%eax
f01035de:	01 d0                	add    %edx,%eax

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01035e0:	8a 11                	mov    (%ecx),%dl
f01035e2:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01035e5:	80 fb 09             	cmp    $0x9,%bl
f01035e8:	77 da                	ja     f01035c4 <strtol+0x77>
			dig = *s - '0';
f01035ea:	0f be d2             	movsbl %dl,%edx
f01035ed:	83 ea 30             	sub    $0x30,%edx
f01035f0:	eb e2                	jmp    f01035d4 <strtol+0x87>
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01035f2:	8d 72 bf             	lea    -0x41(%edx),%esi
f01035f5:	89 f3                	mov    %esi,%ebx
f01035f7:	80 fb 19             	cmp    $0x19,%bl
f01035fa:	77 08                	ja     f0103604 <strtol+0xb7>
			dig = *s - 'A' + 10;
f01035fc:	0f be d2             	movsbl %dl,%edx
f01035ff:	83 ea 37             	sub    $0x37,%edx
f0103602:	eb d0                	jmp    f01035d4 <strtol+0x87>
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103604:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103608:	74 05                	je     f010360f <strtol+0xc2>
		*endptr = (char *) s;
f010360a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010360d:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010360f:	85 ff                	test   %edi,%edi
f0103611:	74 02                	je     f0103615 <strtol+0xc8>
f0103613:	f7 d8                	neg    %eax
}
f0103615:	5b                   	pop    %ebx
f0103616:	5e                   	pop    %esi
f0103617:	5f                   	pop    %edi
f0103618:	5d                   	pop    %ebp
f0103619:	c3                   	ret    
	...

f010361c <__udivdi3>:
f010361c:	55                   	push   %ebp
f010361d:	57                   	push   %edi
f010361e:	56                   	push   %esi
f010361f:	53                   	push   %ebx
f0103620:	83 ec 1c             	sub    $0x1c,%esp
f0103623:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f0103627:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f010362b:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010362f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103633:	89 ca                	mov    %ecx,%edx
f0103635:	89 f8                	mov    %edi,%eax
f0103637:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010363b:	85 f6                	test   %esi,%esi
f010363d:	75 2d                	jne    f010366c <__udivdi3+0x50>
f010363f:	39 cf                	cmp    %ecx,%edi
f0103641:	77 65                	ja     f01036a8 <__udivdi3+0x8c>
f0103643:	89 fd                	mov    %edi,%ebp
f0103645:	85 ff                	test   %edi,%edi
f0103647:	75 0b                	jne    f0103654 <__udivdi3+0x38>
f0103649:	b8 01 00 00 00       	mov    $0x1,%eax
f010364e:	31 d2                	xor    %edx,%edx
f0103650:	f7 f7                	div    %edi
f0103652:	89 c5                	mov    %eax,%ebp
f0103654:	31 d2                	xor    %edx,%edx
f0103656:	89 c8                	mov    %ecx,%eax
f0103658:	f7 f5                	div    %ebp
f010365a:	89 c1                	mov    %eax,%ecx
f010365c:	89 d8                	mov    %ebx,%eax
f010365e:	f7 f5                	div    %ebp
f0103660:	89 cf                	mov    %ecx,%edi
f0103662:	89 fa                	mov    %edi,%edx
f0103664:	83 c4 1c             	add    $0x1c,%esp
f0103667:	5b                   	pop    %ebx
f0103668:	5e                   	pop    %esi
f0103669:	5f                   	pop    %edi
f010366a:	5d                   	pop    %ebp
f010366b:	c3                   	ret    
f010366c:	39 ce                	cmp    %ecx,%esi
f010366e:	77 28                	ja     f0103698 <__udivdi3+0x7c>
f0103670:	0f bd fe             	bsr    %esi,%edi
f0103673:	83 f7 1f             	xor    $0x1f,%edi
f0103676:	75 40                	jne    f01036b8 <__udivdi3+0x9c>
f0103678:	39 ce                	cmp    %ecx,%esi
f010367a:	72 0a                	jb     f0103686 <__udivdi3+0x6a>
f010367c:	3b 44 24 04          	cmp    0x4(%esp),%eax
f0103680:	0f 87 9e 00 00 00    	ja     f0103724 <__udivdi3+0x108>
f0103686:	b8 01 00 00 00       	mov    $0x1,%eax
f010368b:	89 fa                	mov    %edi,%edx
f010368d:	83 c4 1c             	add    $0x1c,%esp
f0103690:	5b                   	pop    %ebx
f0103691:	5e                   	pop    %esi
f0103692:	5f                   	pop    %edi
f0103693:	5d                   	pop    %ebp
f0103694:	c3                   	ret    
f0103695:	8d 76 00             	lea    0x0(%esi),%esi
f0103698:	31 ff                	xor    %edi,%edi
f010369a:	31 c0                	xor    %eax,%eax
f010369c:	89 fa                	mov    %edi,%edx
f010369e:	83 c4 1c             	add    $0x1c,%esp
f01036a1:	5b                   	pop    %ebx
f01036a2:	5e                   	pop    %esi
f01036a3:	5f                   	pop    %edi
f01036a4:	5d                   	pop    %ebp
f01036a5:	c3                   	ret    
f01036a6:	66 90                	xchg   %ax,%ax
f01036a8:	89 d8                	mov    %ebx,%eax
f01036aa:	f7 f7                	div    %edi
f01036ac:	31 ff                	xor    %edi,%edi
f01036ae:	89 fa                	mov    %edi,%edx
f01036b0:	83 c4 1c             	add    $0x1c,%esp
f01036b3:	5b                   	pop    %ebx
f01036b4:	5e                   	pop    %esi
f01036b5:	5f                   	pop    %edi
f01036b6:	5d                   	pop    %ebp
f01036b7:	c3                   	ret    
f01036b8:	bd 20 00 00 00       	mov    $0x20,%ebp
f01036bd:	29 fd                	sub    %edi,%ebp
f01036bf:	89 f9                	mov    %edi,%ecx
f01036c1:	d3 e6                	shl    %cl,%esi
f01036c3:	89 c3                	mov    %eax,%ebx
f01036c5:	89 e9                	mov    %ebp,%ecx
f01036c7:	d3 eb                	shr    %cl,%ebx
f01036c9:	89 d9                	mov    %ebx,%ecx
f01036cb:	09 f1                	or     %esi,%ecx
f01036cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01036d1:	89 f9                	mov    %edi,%ecx
f01036d3:	d3 e0                	shl    %cl,%eax
f01036d5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036d9:	89 d6                	mov    %edx,%esi
f01036db:	89 e9                	mov    %ebp,%ecx
f01036dd:	d3 ee                	shr    %cl,%esi
f01036df:	89 f9                	mov    %edi,%ecx
f01036e1:	d3 e2                	shl    %cl,%edx
f01036e3:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01036e7:	89 e9                	mov    %ebp,%ecx
f01036e9:	d3 eb                	shr    %cl,%ebx
f01036eb:	09 da                	or     %ebx,%edx
f01036ed:	89 d0                	mov    %edx,%eax
f01036ef:	89 f2                	mov    %esi,%edx
f01036f1:	f7 74 24 08          	divl   0x8(%esp)
f01036f5:	89 d6                	mov    %edx,%esi
f01036f7:	89 c3                	mov    %eax,%ebx
f01036f9:	f7 64 24 0c          	mull   0xc(%esp)
f01036fd:	39 d6                	cmp    %edx,%esi
f01036ff:	72 17                	jb     f0103718 <__udivdi3+0xfc>
f0103701:	74 09                	je     f010370c <__udivdi3+0xf0>
f0103703:	89 d8                	mov    %ebx,%eax
f0103705:	31 ff                	xor    %edi,%edi
f0103707:	e9 56 ff ff ff       	jmp    f0103662 <__udivdi3+0x46>
f010370c:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103710:	89 f9                	mov    %edi,%ecx
f0103712:	d3 e2                	shl    %cl,%edx
f0103714:	39 c2                	cmp    %eax,%edx
f0103716:	73 eb                	jae    f0103703 <__udivdi3+0xe7>
f0103718:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010371b:	31 ff                	xor    %edi,%edi
f010371d:	e9 40 ff ff ff       	jmp    f0103662 <__udivdi3+0x46>
f0103722:	66 90                	xchg   %ax,%ax
f0103724:	31 c0                	xor    %eax,%eax
f0103726:	e9 37 ff ff ff       	jmp    f0103662 <__udivdi3+0x46>
	...

f010372c <__umoddi3>:
f010372c:	55                   	push   %ebp
f010372d:	57                   	push   %edi
f010372e:	56                   	push   %esi
f010372f:	53                   	push   %ebx
f0103730:	83 ec 1c             	sub    $0x1c,%esp
f0103733:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103737:	8b 74 24 34          	mov    0x34(%esp),%esi
f010373b:	8b 7c 24 38          	mov    0x38(%esp),%edi
f010373f:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0103743:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103747:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010374b:	89 3c 24             	mov    %edi,(%esp)
f010374e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103752:	89 f2                	mov    %esi,%edx
f0103754:	85 c0                	test   %eax,%eax
f0103756:	75 18                	jne    f0103770 <__umoddi3+0x44>
f0103758:	39 f7                	cmp    %esi,%edi
f010375a:	0f 86 a0 00 00 00    	jbe    f0103800 <__umoddi3+0xd4>
f0103760:	89 c8                	mov    %ecx,%eax
f0103762:	f7 f7                	div    %edi
f0103764:	89 d0                	mov    %edx,%eax
f0103766:	31 d2                	xor    %edx,%edx
f0103768:	83 c4 1c             	add    $0x1c,%esp
f010376b:	5b                   	pop    %ebx
f010376c:	5e                   	pop    %esi
f010376d:	5f                   	pop    %edi
f010376e:	5d                   	pop    %ebp
f010376f:	c3                   	ret    
f0103770:	89 f3                	mov    %esi,%ebx
f0103772:	39 f0                	cmp    %esi,%eax
f0103774:	0f 87 a6 00 00 00    	ja     f0103820 <__umoddi3+0xf4>
f010377a:	0f bd e8             	bsr    %eax,%ebp
f010377d:	83 f5 1f             	xor    $0x1f,%ebp
f0103780:	0f 84 a6 00 00 00    	je     f010382c <__umoddi3+0x100>
f0103786:	bf 20 00 00 00       	mov    $0x20,%edi
f010378b:	29 ef                	sub    %ebp,%edi
f010378d:	89 e9                	mov    %ebp,%ecx
f010378f:	d3 e0                	shl    %cl,%eax
f0103791:	8b 34 24             	mov    (%esp),%esi
f0103794:	89 f2                	mov    %esi,%edx
f0103796:	89 f9                	mov    %edi,%ecx
f0103798:	d3 ea                	shr    %cl,%edx
f010379a:	09 c2                	or     %eax,%edx
f010379c:	89 14 24             	mov    %edx,(%esp)
f010379f:	89 f2                	mov    %esi,%edx
f01037a1:	89 e9                	mov    %ebp,%ecx
f01037a3:	d3 e2                	shl    %cl,%edx
f01037a5:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037a9:	89 de                	mov    %ebx,%esi
f01037ab:	89 f9                	mov    %edi,%ecx
f01037ad:	d3 ee                	shr    %cl,%esi
f01037af:	89 e9                	mov    %ebp,%ecx
f01037b1:	d3 e3                	shl    %cl,%ebx
f01037b3:	8b 54 24 08          	mov    0x8(%esp),%edx
f01037b7:	89 d0                	mov    %edx,%eax
f01037b9:	89 f9                	mov    %edi,%ecx
f01037bb:	d3 e8                	shr    %cl,%eax
f01037bd:	09 d8                	or     %ebx,%eax
f01037bf:	89 d3                	mov    %edx,%ebx
f01037c1:	89 e9                	mov    %ebp,%ecx
f01037c3:	d3 e3                	shl    %cl,%ebx
f01037c5:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01037c9:	89 f2                	mov    %esi,%edx
f01037cb:	f7 34 24             	divl   (%esp)
f01037ce:	89 d6                	mov    %edx,%esi
f01037d0:	f7 64 24 04          	mull   0x4(%esp)
f01037d4:	89 c3                	mov    %eax,%ebx
f01037d6:	89 d1                	mov    %edx,%ecx
f01037d8:	39 d6                	cmp    %edx,%esi
f01037da:	72 7c                	jb     f0103858 <__umoddi3+0x12c>
f01037dc:	74 72                	je     f0103850 <__umoddi3+0x124>
f01037de:	8b 54 24 08          	mov    0x8(%esp),%edx
f01037e2:	29 da                	sub    %ebx,%edx
f01037e4:	19 ce                	sbb    %ecx,%esi
f01037e6:	89 f0                	mov    %esi,%eax
f01037e8:	89 f9                	mov    %edi,%ecx
f01037ea:	d3 e0                	shl    %cl,%eax
f01037ec:	89 e9                	mov    %ebp,%ecx
f01037ee:	d3 ea                	shr    %cl,%edx
f01037f0:	09 d0                	or     %edx,%eax
f01037f2:	89 e9                	mov    %ebp,%ecx
f01037f4:	d3 ee                	shr    %cl,%esi
f01037f6:	89 f2                	mov    %esi,%edx
f01037f8:	83 c4 1c             	add    $0x1c,%esp
f01037fb:	5b                   	pop    %ebx
f01037fc:	5e                   	pop    %esi
f01037fd:	5f                   	pop    %edi
f01037fe:	5d                   	pop    %ebp
f01037ff:	c3                   	ret    
f0103800:	89 fd                	mov    %edi,%ebp
f0103802:	85 ff                	test   %edi,%edi
f0103804:	75 0b                	jne    f0103811 <__umoddi3+0xe5>
f0103806:	b8 01 00 00 00       	mov    $0x1,%eax
f010380b:	31 d2                	xor    %edx,%edx
f010380d:	f7 f7                	div    %edi
f010380f:	89 c5                	mov    %eax,%ebp
f0103811:	89 f0                	mov    %esi,%eax
f0103813:	31 d2                	xor    %edx,%edx
f0103815:	f7 f5                	div    %ebp
f0103817:	89 c8                	mov    %ecx,%eax
f0103819:	f7 f5                	div    %ebp
f010381b:	e9 44 ff ff ff       	jmp    f0103764 <__umoddi3+0x38>
f0103820:	89 c8                	mov    %ecx,%eax
f0103822:	89 f2                	mov    %esi,%edx
f0103824:	83 c4 1c             	add    $0x1c,%esp
f0103827:	5b                   	pop    %ebx
f0103828:	5e                   	pop    %esi
f0103829:	5f                   	pop    %edi
f010382a:	5d                   	pop    %ebp
f010382b:	c3                   	ret    
f010382c:	39 f0                	cmp    %esi,%eax
f010382e:	72 05                	jb     f0103835 <__umoddi3+0x109>
f0103830:	39 0c 24             	cmp    %ecx,(%esp)
f0103833:	77 0c                	ja     f0103841 <__umoddi3+0x115>
f0103835:	89 f2                	mov    %esi,%edx
f0103837:	29 f9                	sub    %edi,%ecx
f0103839:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f010383d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103841:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103845:	83 c4 1c             	add    $0x1c,%esp
f0103848:	5b                   	pop    %ebx
f0103849:	5e                   	pop    %esi
f010384a:	5f                   	pop    %edi
f010384b:	5d                   	pop    %ebp
f010384c:	c3                   	ret    
f010384d:	8d 76 00             	lea    0x0(%esi),%esi
f0103850:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103854:	73 88                	jae    f01037de <__umoddi3+0xb2>
f0103856:	66 90                	xchg   %ax,%ax
f0103858:	2b 44 24 04          	sub    0x4(%esp),%eax
f010385c:	1b 14 24             	sbb    (%esp),%edx
f010385f:	89 d1                	mov    %edx,%ecx
f0103861:	89 c3                	mov    %eax,%ebx
f0103863:	e9 76 ff ff ff       	jmp    f01037de <__umoddi3+0xb2>
