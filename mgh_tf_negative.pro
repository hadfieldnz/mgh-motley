;+
; NAME:
;   MGH_TF_NEGATIVE
;
; PURPOSE:
;   This function is designed for use with the TICKFORMAT and
;   TICKFRMTDATA properties of IDLgrAxis. Given a real value, it
;   returns a string representing the additive inverse.
;
;   MGH_TF_NEGATIVE is a special case of MGH_TF_LINEAR.
;
; CALLING SEQUENCE:
;   Result = MGH_TF_NEGATIVE(Direction, Index, Value)
;
; POSITIONAL PARAMETERS:
;   Direction (input)
;     Axis direction, required by the TICKFORMAT interface but ignored.
;
;   Index (input)
;     Axis index, required by the TICKFORMAT interface but ignored.
;
;   Value (input)
;     The real value to be formatted.
;
; KEYWORD PARAMETERS:
;   DATA (input, structure)
;     Specify this keyword to control the format. The keyword value
;     should be a structure with the tag "format".The default is not
;     to apply an explicit format.
;
; RETURN VALUE:
;   The function returns a scalar string.
;
;###########################################################################
;
; This software is provided subject to the following conditions:
;
; 1.  NIWA makes no representations or warranties regarding the
;     accuracy of the software, the use to which the software may
;     be put or the results to be obtained from the use of the
;     software.  Accordingly NIWA accepts no liability for any loss
;     or damage (whether direct of indirect) incurred by any person
;     through the use of or reliance on the software.
;
; 2.  NIWA is to be acknowledged as the original author of the
;     software where the software is used or presented in any form.
;
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 1999-05:
;     Written.
;   Mark Hadfield, 2002-12:
;     Changed the default number-to-string conversion function from
;     FORMAT_AXIS_VALUES to MGH_FORMAT_FLOAT--see comments in
;     MGH_TF_LONGITUDE.
;-

function MGH_TF_NEGATIVE, direction, index, value, DATA=data

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   format = ''

   if size(data, /TYPE) eq 8 then begin
      if n_elements(data) ne 1 then $
           message, 'The DATA structure must have one element'
      if mgh_struct_has_tag(data, 'format') then $
           format = data.format
   endif

   case strlen(format) gt 0 of
      1: result = string(-value, FORMAT=format)
      0: result = mgh_format_float(-value)
   endcase

   result = strtrim(result[0], 2)

   if abs(value) eq 0 && strmatch(result, '-*') then result = strmid(result, 1)

   return, result

end

