/* ldbuildid.c - Build Id support routines
   Copyright 2013 Free Software Foundation, Inc.

   This file is part of the GNU Binutils.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street - Fifth Floor, Boston,
   MA 02110-1301, USA.  */

#include "sysdep.h"
#include "bfd.h"
#include "safe-ctype.h"
#include "md5.h"
#include "sha1.h"

#include "ldbuildid.h"

bfd_boolean
validate_build_id_style(const char *style)
{
 if ((strcmp (style, "md5") == 0) ||
     (strcmp (style, "sha1") == 0) ||
#ifndef __MINGW32__
     (strcmp (style, "uuid") == 0) ||
#endif
     (strncmp (style, "0x", 2) == 0))
   return TRUE;

 return FALSE;
}

bfd_size_type
compute_build_id_size(const char *style)
{
  if (!strcmp (style, "md5") || !strcmp (style, "uuid"))
    return  128 / 8;
  else if (!strcmp (style, "sha1"))
    return  160 / 8;
  else if (!strncmp (style, "0x", 2))
    {
      bfd_size_type size = 0;
      /* ID is in string form (hex).  Count the bytes */
      const char *id = style + 2;
      do
	{
	  if (ISXDIGIT (id[0]) && ISXDIGIT (id[1]))
	    {
	      ++size;
	      id += 2;
	    }
	  else if (*id == '-' || *id == ':')
	    ++id;
	  else
	    {
	      size = 0;
	      break;
	    }
	} while (*id != '\0');
      return size;
    }
  return 0;
}

static unsigned char
read_hex (const char xdigit)
{
  if (ISDIGIT (xdigit))
    return xdigit - '0';
  if (ISUPPER (xdigit))
    return xdigit - 'A' + 0xa;
  if (ISLOWER (xdigit))
    return xdigit - 'a' + 0xa;
  abort ();
  return 0;
}

bfd_boolean
generate_build_id(bfd *abfd, const char *style, checksum_fn checksum_contents, unsigned char *id_bits)
{
  if (strcmp (style, "md5") == 0)
    {
      struct md5_ctx ctx;
      md5_init_ctx (&ctx);
      if (!(*checksum_contents) (abfd, (sum_fn) &md5_process_bytes, &ctx))
	return FALSE;
      md5_finish_ctx (&ctx, id_bits);
    }
  else if (strcmp (style, "sha1") == 0)
    {
      struct sha1_ctx ctx;
      sha1_init_ctx (&ctx);
      if (!(*checksum_contents) (abfd, (sum_fn) &sha1_process_bytes, &ctx))
	return FALSE;
      sha1_finish_ctx (&ctx, id_bits);
    }
#ifndef __MINGW32__
  else if (strcmp (style, "uuid") == 0)
    {
      int n;
      int fd = open ("/dev/urandom", O_RDONLY);
      int size = 128 / 8;
      if (fd < 0)
	return FALSE;
      n = read (fd, id_bits, size);
      close (fd);
      if (n < size)
        {
          return FALSE;
        }
    }
#endif
  else if (strncmp (style, "0x", 2) == 0)
    {
      /* ID is in string form (hex).  Convert to bits.  */
      const char *id = style + 2;
      size_t n = 0;
      do
	{
	  if (ISXDIGIT (id[0]) && ISXDIGIT (id[1]))
	    {
	      id_bits[n] = read_hex (*id++) << 4;
	      id_bits[n++] |= read_hex (*id++);
	    }
	  else if (*id == '-' || *id == ':')
	    ++id;
	  else
	    abort ();		/* Should have been validated earlier.  */
	} while (*id != '\0');
    }
  else
    abort ();			/* Should have been validated earlier.  */

  return TRUE;
}
