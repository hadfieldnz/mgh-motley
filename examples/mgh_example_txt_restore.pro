;+
; NAME:
;   MGH_EXAMPLE_TXT_RESTORE
;
; PURPOSE:
;   Example code for MGH_TXT_RESTORE funciton.
;
; ARGUMENTS:
;   option:
;       Specify the container type
;
; KEYWORDS:
;   GET:
;       Controls whether to retrieve items from the container after they are
;       added. Default is 0 (not to get).
;
;   N_ITEMS:
;       Number of items to process. Default is 20,000.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-12:
;     Written.
;-
pro mgh_example_txt_restore, $
     COMPRESS=compress, METHOD=method, N_LINES=n_lines, TEMPDIR=tempdir

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(compress) eq 0 then compress = 0

   if n_elements(method) eq 0 then method = 0

   if n_elements(n_lines) eq 0 then n_lines = 20000

   case n_elements(tempdir) gt 0 of
      0: file = filepath(cmunique_id()+'.txt', /TMP)
      1: file = filepath(cmunique_id()+'.txt', ROOT=tempdir)
   endcase

   if keyword_set(compress) then file = file + '.gz'

   message, /INFORM, 'Writing '+strtrim(n_lines,2)+' lines to temporary file '+file

   sample = "The 'Red Death' had long devastated the country,"
   l_sample = strlen(sample)

   openw, lun, file, /GET_LUN, COMPRESS=compress
   for i=0,n_lines-1 do $
        printf, lun, strmid(sample,0,round(l_sample*randomu(seed)))
   free_lun, lun

   t0 = systime(1)

   void = mgh_txt_restore(file, COMPRESS=compress, METHOD=method, COUNT=count)

   t1 = systime(1)

   message, /INFORM, 'Reading temporary file'

   message, /INFORM, 'Reading '+strtrim(count,2)+' lines took '+strtrim(t1-t0, 2)+' s'

   message, /INFORM, 'Deleting temporary file'

   file_delete, file

end
