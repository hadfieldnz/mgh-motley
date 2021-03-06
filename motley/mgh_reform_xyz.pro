;+
; NAME:
;   MGH_REFORM_XYZ
;
; PURPOSE:
;   Given three vectors x, y and z, thought to contain data from a
;   rectilinear grid, where x & y are the 1D coordiante variables and
;   z is the 2D data variable, recover the original gridded data.
;
; CALLING SEQUENCE:
;   mgh_reform_xyz, x, y, z, grid_x, grid_y, grid_z
;
; POSITIONAL PARAMETERS:
;   x, y, z (input, numeric vector)
;     The input x, y and z data
;
;   grid_x, grid_y (output, numeric vector)
;     The sorted, unique values of x & y respectively/
;
;   grid_z (output, numeric 2-D array)
;     An array dimensioned [n_elements(grid_x),n_elements(grid_y)] with
;     z values inserted at indices determined from the corresponding x
;     & y, and all others NaN
;
;###########################################################################
; Copyright (c) 2009 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2009-11:
;     Written
;-
pro mgh_reform_xyz, x, y, z, grid_x, grid_y, grid_z

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(x) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'a'
   if n_elements(y) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'y'
   if n_elements(z) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'z'

   n = n_elements(x)

   if n_elements(y) ne n then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'y'
   if n_elements(z) ne n then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'z'

   grid_x = x[uniq(x, sort(x))]
   grid_y = y[uniq(y, sort(y))]

   dim = [n_elements(grid_x),n_elements(grid_y)]

   grid_z = make_array(dim, TYPE=size(z, /TYPE))

   ii = round(mgh_locate(grid_x, XOUT=x))
   jj = round(mgh_locate(grid_y, XOUT=y))

   grid_z[ii,jj] = z

end
