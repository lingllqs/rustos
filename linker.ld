ENTRY(_start)

SECTIONS
{
	. = 100000

	.text = : {
		*(.text*)
	}

	.rodata = : {
		*(.rodata*)
	}

	.data = : {
		*(.data*)
	}

	.bss = : {
		*(.bss*)
	}
}
