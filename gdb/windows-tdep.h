/* Copyright (C) 2008-2016 Free Software Foundation, Inc.

   This file is part of GDB.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

#ifndef WINDOWS_TDEP_H
#define WINDOWS_TDEP_H

struct obstack;
struct gdbarch;

extern struct cmd_list_element *info_w32_cmdlist;

extern void init_w32_command_list (void);

extern void windows_xfer_shared_library (const char* so_name,
					 CORE_ADDR load_addr,
					 struct gdbarch *gdbarch,
					 struct obstack *obstack);

extern void windows_init_abi (struct gdbarch_info info,
			      struct gdbarch *gdbarch);

extern const struct frame_unwind cygwin_sigwrapper_frame_unwind;

/* An instruction to match.  */
struct insn_pattern
{
  gdb_byte data;            /* See if it matches this....  */
  gdb_byte mask;            /* ... with this mask.  */
};

struct insn_pattern_sequence
{
  const struct insn_pattern *pattern;
  int length;
};

extern void cygwin_sigwrapper_frame_unwind_set_sigbe_pattern(
			const struct insn_pattern_sequence *pattern);
extern void cygwin_sigwrapper_frame_unwind_set_sigdelayed_pattern(
			 const struct insn_pattern_sequence *pattern);

#endif
