# This shell script emits a C file. -*- C -*-
# It does some substitutions.
cat >e${EMULATION_NAME}.c <<EOF
/* This file is is generated by a shell script.  DO NOT EDIT! */

/* An emulation for HP PA-RISC ELF linkers.
   Copyright (C) 1991, 93, 94, 95, 97, 99, 2000
   Free Software Foundation, Inc.
   Written by Steve Chamberlain steve@cygnus.com

This file is part of GLD, the Gnu Linker.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

#include "bfd.h"
#include "sysdep.h"
#include <ctype.h>
#include "bfdlink.h"

#include "ld.h"
#include "ldmain.h"
#include "ldemul.h"
#include "ldfile.h"
#include "ldmisc.h"
#include "ldexp.h"
#include "ldlang.h"
#include "ldgram.h"
#include "ldctor.h"
#include "elf32-hppa.h"

static void hppaelf_before_parse PARAMS ((void));
static void hppaelf_set_output_arch PARAMS ((void));
static void hppaelf_create_output_section_statements PARAMS ((void));
static void hppaelf_delete_padding_statements
  PARAMS ((lang_statement_list_type *list));
static void hppaelf_finish PARAMS ((void));
static boolean gld${EMULATION_NAME}_place_orphan
  PARAMS ((lang_input_statement_type *, asection *));
static lang_output_section_statement_type *output_rel_find PARAMS ((void));
static char *hppaelf_get_script PARAMS ((int *));


/* Fake input file for stubs.  */
static lang_input_statement_type *stub_file;

/* Perform some emulation specific initialization.  For PA ELF we set
   up the local label prefix and the output architecture.  */

static void
hppaelf_before_parse ()
{
  ldfile_output_architecture = bfd_arch_hppa;
}

/* Set the output architecture and machine.  */

static void
hppaelf_set_output_arch()
{
  unsigned long machine = 0;

  bfd_set_arch_mach (output_bfd, ldfile_output_architecture, machine);
}

/* This is called before the input files are opened.  We create a new
   fake input file to hold the stub sections.  */

static void
hppaelf_create_output_section_statements ()
{
  stub_file = lang_add_input_file ("linker stubs",
				   lang_input_file_is_fake_enum,
				   NULL);
  stub_file->the_bfd = bfd_create ("linker stubs", output_bfd);
  if (stub_file->the_bfd == NULL
      || ! bfd_set_arch_mach (stub_file->the_bfd,
			      bfd_get_arch (output_bfd),
			      bfd_get_mach (output_bfd)))
    {
      einfo ("%X%P: can not create BFD %E\n");
      return;
    }

  ldlang_add_file (stub_file);
}

/* Walk all the lang statements splicing out any padding statements from
   the list.  */

static void
hppaelf_delete_padding_statements (list)
     lang_statement_list_type *list;
{
  lang_statement_union_type *s;
  lang_statement_union_type **ps;
  for (ps = &list->head; (s = *ps) != NULL; ps = &s->next)
    {
      switch (s->header.type)
	{

	/* We want to recursively walk these sections.  */
	case lang_constructors_statement_enum:
	  hppaelf_delete_padding_statements (&constructor_list);
	  break;

	case lang_output_section_statement_enum:
	  hppaelf_delete_padding_statements (&s->output_section_statement.children);
	  break;

	case lang_group_statement_enum:
	  hppaelf_delete_padding_statements (&s->group_statement.children);
	  break;

	case lang_wild_statement_enum:
	  hppaelf_delete_padding_statements (&s->wild_statement.children);
	  break;

	/* Here's what we are really looking for.  Splice these out of
	   the list.  */
	case lang_padding_statement_enum:
	  *ps = s->next;
	  if (*ps == NULL)
	    list->tail = ps;
	  break;

	/* We don't care about these cases.  */
	case lang_data_statement_enum:
	case lang_object_symbols_statement_enum:
	case lang_output_statement_enum:
	case lang_target_statement_enum:
	case lang_input_section_enum:
	case lang_input_statement_enum:
	case lang_assignment_statement_enum:
	case lang_address_statement_enum:
	  break;

	default:
	  abort ();
	  break;
	}
    }
}


struct hook_stub_info
{
  lang_statement_list_type add;
  asection *input_section;
};

/* Traverse the linker tree to find the spot where the stub goes.  */

static boolean
hook_in_stub (info, lp)
     struct hook_stub_info *info;
     lang_statement_union_type **lp;
{
  lang_statement_union_type *l;
  boolean ret;

  for (; (l = *lp) != NULL; lp = &l->next)
    {
      switch (l->header.type)
	{
	case lang_constructors_statement_enum:
	  ret = hook_in_stub (info, &constructor_list.head);
	  if (ret)
	    return ret;
	  break;

	case lang_output_section_statement_enum:
	  ret = hook_in_stub (info,
			      &l->output_section_statement.children.head);
	  if (ret)
	    return ret;
	  break;

	case lang_wild_statement_enum:
	  ret = hook_in_stub (info, &l->wild_statement.children.head);
	  if (ret)
	    return ret;
	  break;

	case lang_group_statement_enum:
	  ret = hook_in_stub (info, &l->group_statement.children.head);
	  if (ret)
	    return ret;
	  break;

	case lang_input_section_enum:
	  if (l->input_section.section == info->input_section)
	    {
	      /* We've found our section.  Insert the stub immediately
		 before its associated input section.  */
	      *lp = info->add.head;
	      *(info->add.tail) = l;
	      return true;
	    }
	  break;

	case lang_data_statement_enum:
	case lang_reloc_statement_enum:
	case lang_object_symbols_statement_enum:
	case lang_output_statement_enum:
	case lang_target_statement_enum:
	case lang_input_statement_enum:
	case lang_assignment_statement_enum:
	case lang_padding_statement_enum:
	case lang_address_statement_enum:
	case lang_fill_statement_enum:
	  break;

	default:
	  FAIL ();
	  break;
	}
    }
  return false;
}

/* Call-back for elf32_hppa_size_stubs.  */

/* Create a new stub section, and arrange for it to be linked
   immediately before INPUT_SECTION.  */

static asection *
hppaelf_add_stub_section (stub_name, input_section)
     const char *stub_name;
     asection *input_section;
{
  asection *stub_sec;
  flagword flags;
  asection *output_section;
  const char *secname;
  lang_output_section_statement_type *os;
  struct hook_stub_info info;

  stub_sec = bfd_make_section_anyway (stub_file->the_bfd, stub_name);
  if (stub_sec == NULL)
    goto err_ret;

  flags = (SEC_ALLOC | SEC_LOAD | SEC_READONLY | SEC_CODE
	   | SEC_HAS_CONTENTS | SEC_IN_MEMORY | SEC_KEEP);
  if (!bfd_set_section_flags (stub_file->the_bfd, stub_sec, flags))
    goto err_ret;

  output_section = input_section->output_section;
  secname = bfd_get_section_name (output_section->owner, output_section);
  os = lang_output_section_find (secname);

  info.input_section = input_section;
  lang_list_init (&info.add);
  wild_doit (&info.add, stub_sec, os, stub_file);

  if (info.add.head == NULL)
    goto err_ret;

  if (hook_in_stub (&info, &os->children.head))
    return stub_sec;

 err_ret:
  einfo ("%X%P: can not make stub section: %E\n");
  return NULL;
}

/* Another call-back for elf32_hppa_size_stubs.  */

static void
hppaelf_layaout_sections_again ()
{
  /* If we have changed sizes of the stub sections, then we need
     to recalculate all the section offsets.  This may mean we need to
     add even more stubs.  */

  /* Delete all the padding statements, they're no longer valid.  */
  hppaelf_delete_padding_statements (stat_ptr);

  /* Resize the sections.  */
  lang_size_sections (stat_ptr->head, abs_output_section,
		      &stat_ptr->head, 0, (bfd_vma) 0, false);

  /* Redo special stuff.  */
  ldemul_after_allocation ();

  /* Do the assignments again.  */
  lang_do_assignments (stat_ptr->head, abs_output_section,
		       (fill_type) 0, (bfd_vma) 0);
}


/* Final emulation specific call.  For the PA we use this opportunity
   to build linker stubs.  */

static void
hppaelf_finish ()
{
  /* If generating a relocateable output file, then we don't
     have to examine the relocs.  */
  if (link_info.relocateable)
    return;

  /* Call into the BFD backend to do the real work.  */
  if (elf32_hppa_size_stubs (stub_file->the_bfd,
			     &link_info,
			     &hppaelf_add_stub_section,
			     &hppaelf_layaout_sections_again) == false)
    {
      einfo ("%X%P: can not size stub section: %E\n");
      return;
    }

  /* Now build the linker stubs.  */
  if (stub_file->the_bfd->sections != NULL)
    {
      if (elf32_hppa_build_stubs (stub_file->the_bfd, &link_info) == false)
	einfo ("%X%P: can not build stubs: %E\n");
    }
}


/* Place an orphan section.  We use this to put random SHF_ALLOC
   sections in the right segment.  */

struct orphan_save
{
  lang_output_section_statement_type *os;
  asection **section;
  lang_statement_union_type **stmt;
};

/*ARGSUSED*/
static boolean
gld${EMULATION_NAME}_place_orphan (file, s)
     lang_input_statement_type *file;
     asection *s;
{
  static struct orphan_save hold_text;
  static struct orphan_save hold_rodata;
  static struct orphan_save hold_data;
  static struct orphan_save hold_bss;
  static struct orphan_save hold_rel;
  static struct orphan_save hold_interp;
  struct orphan_save *place;
  lang_statement_list_type *old;
  lang_statement_list_type add;
  etree_type *address;
  const char *secname, *ps;
  const char *outsecname;
  lang_output_section_statement_type *os;

  secname = bfd_get_section_name (s->owner, s);

  /* Look through the script to see where to place this section.  */
  os = lang_output_section_find (secname);

  if (os != NULL
      && os->bfd_section != NULL
      && ((s->flags ^ os->bfd_section->flags) & (SEC_LOAD | SEC_ALLOC)) == 0)
    {
      /* We have already placed a section with this name.  */
      wild_doit (&os->children, s, os, file);
      return true;
    }

  if (hold_text.os == NULL)
    hold_text.os = lang_output_section_find (".text");

  /* If this is a final link, then always put .gnu.warning.SYMBOL
     sections into the .text section to get them out of the way.  */
  if (! link_info.shared
      && ! link_info.relocateable
      && strncmp (secname, ".gnu.warning.", sizeof ".gnu.warning." - 1) == 0
      && hold_text.os != NULL)
    {
      wild_doit (&hold_text.os->children, s, hold_text.os, file);
      return true;
    }

  /* Decide which segment the section should go in based on the
     section name and section flags.  We put loadable .note sections
     right after the .interp section, so that the PT_NOTE segment is
     stored right after the program headers where the OS can read it
     in the first page.  */
#define HAVE_SECTION(hold, name) \
(hold.os != NULL || (hold.os = lang_output_section_find (name)) != NULL)

  if (s->flags & SEC_EXCLUDE)
    return false;
  else if ((s->flags & SEC_ALLOC) == 0)
    place = NULL;
  else if ((s->flags & SEC_LOAD) != 0
	   && strncmp (secname, ".note", 4) == 0
	   && HAVE_SECTION (hold_interp, ".interp"))
    place = &hold_interp;
  else if ((s->flags & SEC_HAS_CONTENTS) == 0
	   && HAVE_SECTION (hold_bss, ".bss"))
    place = &hold_bss;
  else if ((s->flags & SEC_READONLY) == 0
	   && HAVE_SECTION (hold_data, ".data"))
    place = &hold_data;
  else if (strncmp (secname, ".rel", 4) == 0
	   && (hold_rel.os != NULL
	       || (hold_rel.os = output_rel_find ()) != NULL))
    place = &hold_rel;
  else if ((s->flags & SEC_CODE) == 0
	   && (s->flags & SEC_READONLY) != 0
	   && HAVE_SECTION (hold_rodata, ".rodata"))
    place = &hold_rodata;
  else if ((s->flags & SEC_READONLY) != 0
	   && hold_text.os != NULL)
    place = &hold_text;
  else
    place = NULL;

#undef HAVE_SECTION

  /* Choose a unique name for the section.  This will be needed if the
     same section name appears in the input file with different
     loadable or allocateable characteristics.  */
  outsecname = secname;
  if (bfd_get_section_by_name (output_bfd, outsecname) != NULL)
    {
      unsigned int len;
      char *newname;
      unsigned int i;

      len = strlen (outsecname);
      newname = xmalloc (len + 5);
      strcpy (newname, outsecname);
      i = 0;
      do
	{
	  sprintf (newname + len, "%d", i);
	  ++i;
	}
      while (bfd_get_section_by_name (output_bfd, newname) != NULL);

      outsecname = newname;
    }

  if (place != NULL)
    {
      /* Start building a list of statements for this section.  */
      old = stat_ptr;
      stat_ptr = &add;
      lang_list_init (stat_ptr);

      /* If the name of the section is representable in C, then create
	 symbols to mark the start and the end of the section.  */
      for (ps = outsecname; *ps != '\0'; ps++)
	if (! isalnum ((unsigned char) *ps) && *ps != '_')
	  break;
      if (*ps == '\0' && config.build_constructors)
	{
	  char *symname;
	  etree_type *e_align;

	  symname = (char *) xmalloc (ps - outsecname + sizeof "__start_");
	  sprintf (symname, "__start_%s", outsecname);
	  e_align = exp_unop (ALIGN_K,
			      exp_intop ((bfd_vma) 1 << s->alignment_power));
	  lang_add_assignment (exp_assop ('=', symname, e_align));
	}
    }

  if (link_info.relocateable || (s->flags & (SEC_LOAD | SEC_ALLOC)) == 0)
    address = exp_intop ((bfd_vma) 0);
  else
    address = NULL;

  os = lang_enter_output_section_statement (outsecname, address, 0,
					    (bfd_vma) 0,
					    (etree_type *) NULL,
					    (etree_type *) NULL,
					    (etree_type *) NULL);

  wild_doit (&os->children, s, os, file);

  lang_leave_output_section_statement
    ((bfd_vma) 0, "*default*",
     (struct lang_output_section_phdr_list *) NULL, "*default*");

  if (place != NULL)
    {
      asection *snew, **pps;

      stat_ptr = &add;

      if (*ps == '\0' && config.build_constructors)
	{
	  char *symname;

	  symname = (char *) xmalloc (ps - outsecname + sizeof "__stop_");
	  sprintf (symname, "__stop_%s", outsecname);
	  lang_add_assignment (exp_assop ('=', symname,
					  exp_nameop (NAME, ".")));
	}
      stat_ptr = old;

      snew = os->bfd_section;
      if (place->os->bfd_section != NULL || place->section != NULL)
	{
	  /* Shuffle the section to make the output file look neater.  */
	  if (place->section == NULL)
	    {
#if 0
	      /* Finding the end of the list is a little tricky.  We
		 make a wild stab at it by comparing section flags.  */
	      flagword first_flags = place->os->bfd_section->flags;
	      for (pps = &place->os->bfd_section->next;
		   *pps != NULL && (*pps)->flags == first_flags;
		   pps = &(*pps)->next)
		;
	      place->section = pps;
#else
	      /* Put orphans after the first section on the list.  */
	      place->section = &place->os->bfd_section->next;
#endif
	    }

	  /*  Unlink the section.  */
	  for (pps = &output_bfd->sections; *pps != snew; pps = &(*pps)->next)
	    ;
	  *pps = snew->next;

	  /* Now tack it on to the "place->os" section list.  */
	  snew->next = *place->section;
	  *place->section = snew;
	}
      place->section = &snew->next;	/* Save the end of this list.  */

      if (place->stmt == NULL)
	{
	  /* Put the new statement list right at the head.  */
	  *add.tail = place->os->header.next;
	  place->os->header.next = add.head;
	}
      else
	{
	  /* Put it after the last orphan statement we added.  */
	  *add.tail = *place->stmt;
	  *place->stmt = add.head;
	}
      place->stmt = add.tail;		/* Save the end of this list.  */
    }

  return true;
}

/* A variant of lang_output_section_find.  */
static lang_output_section_statement_type *
output_rel_find ()
{
  lang_statement_union_type *u;
  lang_output_section_statement_type *lookup;

  for (u = lang_output_section_statement.head;
       u != (lang_statement_union_type *) NULL;
       u = lookup->next)
    {
      lookup = &u->output_section_statement;
      if (strncmp (".rel", lookup->name, 4) == 0
	  && lookup->bfd_section != NULL
	  && (lookup->bfd_section->flags & SEC_ALLOC) != 0)
	{
	  return lookup;
	}
    }
  return (lang_output_section_statement_type *) NULL;
}

/* The script itself gets inserted here.  */

static char *
hppaelf_get_script(isfile)
     int *isfile;
EOF

if test -n "$COMPILE_IN"
then
# Scripts compiled in.

# sed commands to quote an ld script as a C string.
sc="-f stringify.sed"

cat >>e${EMULATION_NAME}.c <<EOF
{
  *isfile = 0;

  if (link_info.relocateable == true && config.build_constructors == true)
    return
EOF
sed $sc ldscripts/${EMULATION_NAME}.xu                     >> e${EMULATION_NAME}.c
echo '  ; else if (link_info.relocateable == true) return' >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.xr                     >> e${EMULATION_NAME}.c
echo '  ; else if (!config.text_read_only) return'         >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.xbn                    >> e${EMULATION_NAME}.c
echo '  ; else if (!config.magic_demand_paged) return'     >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.xn                     >> e${EMULATION_NAME}.c

if test -n "$GENERATE_SHLIB_SCRIPT" ; then
echo '  ; else if (link_info.shared) return'		   >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.xs                     >> e${EMULATION_NAME}.c
fi

echo '  ; else return'                                     >> e${EMULATION_NAME}.c
sed $sc ldscripts/${EMULATION_NAME}.x                      >> e${EMULATION_NAME}.c
echo '; }'                                                 >> e${EMULATION_NAME}.c

else
# Scripts read from the filesystem.

cat >>e${EMULATION_NAME}.c <<EOF
{			     
  *isfile = 1;

  if (link_info.relocateable == true && config.build_constructors == true)
    return "ldscripts/${EMULATION_NAME}.xu";
  else if (link_info.relocateable == true)
    return "ldscripts/${EMULATION_NAME}.xr";
  else if (!config.text_read_only)
    return "ldscripts/${EMULATION_NAME}.xbn";
  else if (!config.magic_demand_paged)
    return "ldscripts/${EMULATION_NAME}.xn";
  else if (link_info.shared)
    return "ldscripts/${EMULATION_NAME}.xs";
  else
    return "ldscripts/${EMULATION_NAME}.x";
}
EOF

fi

cat >>e${EMULATION_NAME}.c <<EOF

struct ld_emulation_xfer_struct ld_${EMULATION_NAME}_emulation =
{
  hppaelf_before_parse,
  syslib_default,
  hll_default,
  after_parse_default,
  after_open_default,
  after_allocation_default,
  hppaelf_set_output_arch,
  ldemul_default_target,
  before_allocation_default,
  hppaelf_get_script,
  "${EMULATION_NAME}",
  "elf32-hppa",
  hppaelf_finish,
  hppaelf_create_output_section_statements,
  NULL,		/* open dynamic */
  gld${EMULATION_NAME}_place_orphan,
  NULL,		/* set_symbols */
  NULL,		/* parse_args */
  NULL,		/* unrecognized_file */
  NULL,		/* list_options */
  NULL,		/* recognized_file */
  NULL		/* find_potential_libraries */
};
EOF
