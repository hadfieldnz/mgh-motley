;+
; CLASS:
;   MGH_DGplayer
;
; PURPOSE:
;   A window for displaying & managing direct graphics sequences
;
; CATEGORY:
;       Widgets, Direct Graphics.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported:
;
;   CUMULATIVE (Init, Get, Set)
;     The number of frames to superpose on each display. Default is
;     1. If CUMULATIVE is zero or negative then all frames up to the
;     current one are superposed.
;
;   N_FRAMES (Get)
;     The number of frames currently managed by the animator.
;
;   SLAVE (Init, Get, Set)
;     Set this property to specify that the player will be controlled
;     externally.
;
;###########################################################################
; Copyright (c) 2001-2015 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2001-09:
;     Written.
;   Mark Hadfield, 2002-10:
;     - Updated for IDL 5.6.
;     - Fixed up code, which had been thoroughly broken by changes in
;       MGH_DGwindow.
;   Mark Hadfield, 2004-05:
;     A light overhaul for IDL 6.1: accelerator keys added and some of the
;     animation code modernised.
;   Mark Hadfield, 2015-05:
;     Removed the facility to launch a clipboard viewer: the viewer is no
;     longer available in Windows.
;   Mark Hadfield, 2016-11:
;     AVI files are now written (MPEG4 codec) using the IDLffVideoWrite
;     object.
;-

; MGH_DGplayer::Init
;
function MGH_DGplayer::Init, anim, $
     ANIMATION=animation, CUMULATIVE=cumulative, PLAYBACK=playback, SLAVE=slave, $
     _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Process animation arguments

   if n_elements(animation) eq 0 && n_elements(anim) gt 0 then animation = anim

   ;; Properties

   self.cumulative = n_elements(cumulative) gt 0 ? cumulative : 1L

   ;; Initialise the widget base

   ok = self->MGH_DGwindow::Init(/USE_PIXMAP, _STRICT_EXTRA=extra)
   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_DGwindow'

   ;; Add the animator

   self->NewChild, /OBJECT, 'MGH_Animator', CLIENT=self, /ALIGN_CENTER, $
        PLAYBACK=playback, SLAVE=slave, RESULT=oanim
   self.animator = oanim

   ;; Load the animation.

   if obj_valid(animation) then self.animation = animation

   ;; Finalise

   self->Finalize, 'MGH_DGplayer'

   return, 1

end


; MGH_DGplayer::Cleanup
;
pro MGH_DGplayer::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obj_destroy, self.animation

   obj_destroy, self.animator

   self->MGH_DGwindow::Cleanup

end


; MGH_DGplayer::GetProperty
;
pro MGH_DGplayer::GetProperty, $
     ANIMATION=animation, CUMULATIVE=cumulative, N_FRAMES=n_frames, PLAYBACK=playback, $
     POSITION=position, SLAVE=slave, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   animation = self.animation

   cumulative = self.cumulative

   if arg_present(n_frames) then $
        n_frames = obj_valid(self.animation) ? self.animation->N_Frames() : 0

   if obj_valid(self.animator) then begin
      self.animator->GetProperty, $
           PLAYBACK=playback, POSITION=position, SLAVE=slave
   endif

   self->MGH_DGwindow::GetProperty, _STRICT_EXTRA=extra

END

; MGH_DGplayer::SetProperty
;
pro MGH_DGplayer::SetProperty, $
     ANIMATION=animation, CUMULATIVE=cumulative, PLAYBACK=playback, POSITION=position, $
     SLAVE=slave, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(animation) gt 0 then $
        self.animation = animation

   if n_elements(cumulative) gt 0 then $
        self.cumulative = cumulative

   if obj_valid(self.animator) then begin
      self.animator->SetProperty, $
           PLAYBACK=playback, POSITION=position, SLAVE=slave
   endif

   self->MGH_DGwindow::SetProperty, _STRICT_EXTRA=extra

end

; MGH_DGplayer::About
;
pro MGH_DGplayer::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_DGwindow::About, lun

   printf, lun, FORMAT='(%"%s: the animation is %s")', $
        mgh_obj_string(self), mgh_obj_string(self.animation, /SHOW_NAME)

end

; MGH_DGplayer::AssembleFrame
;
pro MGH_DGplayer::AssembleFrame, position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; This method can assume that position will always be a
   ;; defined, scalar integer >= 0.

   self.animation->GetProperty, MULTIPLE=multiple

   case multiple of
      0B: begin
         frame = position
      end
      1B: begin
         p0 = (position-self.cumulative+1) > 0
         p1 = position
         frame = p0 + lindgen(p1-p0+1)
      end
   endcase

   self.animation->AssembleFrame, frame

end

; MGH_DGplayer::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_DGplayer::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ widget_info(self.menu_bar, /VALID_ID) then return

   if widget_info(self.menu_bar, /CHILD) gt 0 then $
        message, 'The menu bar already has children'

   iswin = strcmp(!version.os_family, 'Windows', /FOLD_CASE)

   ;; Create a pulldown menu object with top-level items.

   obar = obj_new('MGH_GUI_PDmenu', BASE=self.menu_bar, /MBAR, $
                  ['File','Edit','Tools','Window','Help'])

   ;; Populate menus in turn...

   ;; ...File menu

   obar->NewItem, PARENT='File', $
        ['Save...','Export Animation','Export Frame','Print Frame','Close'], $
        MENU=[0,1,1,0,0], SEPARATOR=[0,1,0,1,1], $
        ACCELERATOR=['Ctrl+S','','','Ctrl+P','Ctrl+F4']

   fmt = ['FLC...','TIFF...','ZIP...']
   if mgh_has_video(FORMAT='avi', CODEC='mpeg4') then fmt = [fmt,'AVI...']
   if mgh_has_video(FORMAT='mp4') then fmt = [fmt,'MP4...']
   obar->NewItem, PARENT='File.Export Animation', fmt[uniq(fmt, sort(fmt))]
   mgh_undefine, fmt

   fmt = ['EPS...','JPEG...','PNG...']
   if iswin then fmt = [fmt,'WMF...']
   obar->NewItem, PARENT='File.Export Frame', fmt[uniq(fmt, sort(fmt))]
   mgh_undefine, fmt

   ;; ...Edit menu

   obar->NewItem, PARENT='Edit', MENU=[0], SEPARATOR=[0], $
        ['Copy Frame']

   ;; ...Tools menu

   case iswin of
      0: begin
         obar->NewItem, PARENT='Tools', SEPARATOR=[0,1,1,0], $
              ['Time Animation','Export Data...','Set Resizeable...', $
               'Set Cumulative...']
      end
      1: begin
         obar->NewItem, PARENT='Tools', SEPARATOR=[0,1,1,1,0], $
              ['Time Animation','Export Data...', $
               'Set Resizeable...', 'Set Cumulative...']
      end
   endcase

   ;; ...Window menu

   obar->NewItem, PARENT='Window', ['Update','Expand/Collapse'], MENU=[0,1]

   obar->NewItem, PARENT='Window.Expand/Collapse', $
        ['Status Bar','Slider Bar','Play Bar','Delay Bar','Range Bar']

   ;; ...Help menu

   obar->NewItem, PARENT='Help', ['About']

end


; MGH_DGplayer::Display
;
pro MGH_DGplayer::Display, position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; This method can assume that position will always be a
   ;; defined scalar integer, but may be negative--this will
   ;; occur if the number of frames is 0.

   if position ge 0 then begin

      self->SetProperty, COMMANDS=self.animation->AssembleFrame(position)

      self->Draw

      self.animator->GetProperty, SLAVE=slave

      if slave then begin
         self.animator->SetProperty, POSITION=position
         self.animator->UpdateSliderBar
      endif

   end

end

; MGH_DGplayer::EventMenuBar
;
function MGH_DGplayer::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'FILE.EXPORT ANIMATION.AVI': begin
         self->GetProperty, NAME=name
         ext = '.avi'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            mgh_cd_sticky, file_dirname(filename)
            self->WriteAnimationToVideoFile, filename, DISPLAY=!false, FORMAT='avi', CODEC='mpeg4'
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.FLC': begin
         self->GetProperty, NAME=name
         ext = '.flc'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 1 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WriteAnimationToMovieFile, filename, TYPE='FLC'
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.MP4': begin
         self->GetProperty, NAME=name
         ext = '.mp4'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WriteAnimationToVideoFile, filename, DISPLAY=!false
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.TIFF': begin
         self->GetProperty, NAME=name
         ext = '.tif'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 1 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WriteAnimationToMovieFile, filename, TYPE='TIFF'
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.ZIP': begin
         self->GetProperty, NAME=name
         ext = '.zip'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 1 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WriteAnimationToMovieFile, filename, TYPE='ZIP'
         endif
         return, 0
      end

      'FILE.EXPORT FRAME.EPS': begin
         self->GetProperty, NAME=name
         ext = '.eps'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToPostscriptFile, filename
         endif
         return, 0
      end

      'FILE.EXPORT FRAME.JPEG': begin
         self->GetProperty, NAME=name
         ext = '.jpg'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToImageFile, filename, /JPEG
         endif
         return, 0
      end

      'FILE.EXPORT FRAME.PNG': begin
         self->GetProperty, NAME=name
         ext = '.png'
         default_file = strlen(name) gt 0 ? mgh_str_vanilla(name)+ext : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToImageFile, filename, /PNG
         endif
         return, 0
      end

      'FILE.EXPORT FRAME.WMF': begin
         self->GetProperty, NAME=name
         ext = '.wmf'
         default_file = strlen(name) gt 0 ? mgh_str_subst(name,' ','_')+ext : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            mgh_cd_sticky, file_dirname(filename)
            self->WritePictureToMetaFile, filename
         endif
         return, 0
      end

      'FILE.PRINT FRAME': begin
         if dialog_printersetup() then begin
            widget_control, HOURGLASS=1
            self->WritePictureToPrinter
         endif
         return, 0
      end

      'EDIT.COPY FRAME': begin
         widget_control, HOURGLASS=1
         self->WritePictureToClipboard
      end

      'FILE.CLOSE': begin
         self->Kill
         return,1
      end

      'TOOLS.TIME ANIMATION': begin
         self.animator->TimeFrames
      end

      'TOOLS.EXPORT DATA': begin
         self->ExportData, values, labels
         ogui = obj_new('MGH_GUI_Export', values, labels, /BLOCK, /FLOATING, GROUP_LEADER=self.base)
         ogui->Manage
         obj_destroy, ogui
         return, 0
      end

      'TOOLS.SET RESIZEABLE': begin
         mgh_new, 'MGH_GUI_SetList', CAPTION='Resizeable', CLIENT=self $
                  , /FLOATING, GROUP_LEADER=self.base, /IMMEDIATE $
                  , ITEM_STRING=['No Resize','Resize','Preserve Aspect'] $
                  , PROPERTY_NAME='RESIZEABLE'
         return, 0
      end

      'TOOLS.SET CUMULATIVE': begin
         mgh_new, 'MGH_GUI_SetArray', CAPTION='Cumulative', CLIENT=self, $
                  /FLOATING, GROUP_LEADER=self.base, /IMMEDIATE, /INTEGER, $
                  N_ELEMENTS=1, PROPERTY_NAME='CUMULATIVE'
         return, 0
      end

      'WINDOW.UPDATE': begin
         self->Update
         return, 0
      end

      'WINDOW.EXPAND/COLLAPSE.STATUS BAR': begin
         self->BuildStatusBar
         self->UpdateStatusBar
         self->UpdateStatusContext
         return, 0
      end

      'WINDOW.EXPAND/COLLAPSE.SLIDER BAR': begin
         self.animator->BuildSliderBar
         self.animator->UpdateSliderBar
         self.animator->UpdateSliderContext
         return, 0
      end

      'WINDOW.EXPAND/COLLAPSE.PLAY BAR': begin
         self.animator->BuildPlayBar
         self.animator->UpdatePlayBar
         self.animator->UpdatePlayContext
         return, 0
      end

      'WINDOW.EXPAND/COLLAPSE.DELAY BAR': begin
         self.animator->BuildDelayBar
         self.animator->UpdateDelayBar
         self.animator->UpdateDelayContext
         return, 0
      end

      'WINDOW.EXPAND/COLLAPSE.RANGE BAR': begin
         self.animator->BuildRangeBar
         self.animator->UpdateRangeBar
         self.animator->UpdateRangeContext
         return, 0
      end

      'HELP.ABOUT': begin
         self->About
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_DGplayer::ExportData
;
pro MGH_DGplayer::ExportData, values, labels

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_DGwindow::ExportData, values, labels

   self->GetProperty, ANIMATION=animation

   labels = [labels, 'Animation']
   values = [values, ptr_new(animation)]

end

; MGH_DGplayer::Resize
;
pro MGH_DGplayer::Resize, x, y

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, GEOMETRY=geom_base

   if obj_valid(self.animator) then begin
      self.animator->GetProperty, GEOMETRY=geom_animator
      y = y - geom_animator.scr_ysize - geom_base.space
   endif

   self->MGH_DGwindow::Resize, x, y

end

; MGH_DGplayer::Update
;
pro MGH_DGplayer::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_DGwindow::Update

   self.animator->Update

end

; MGH_DGplayer::UpdateMenuBar
;
pro MGH_DGplayer::UpdateMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then begin

      self->GetProperty, ANIMATION=animation, N_FRAMES=n_frames, EXPAND_STATUS_BAR=expand_status_bar

      valid = obj_valid(animation)

      self.animator->GetProperty, SLAVE=slave, $
           EXPAND_DELAY_BAR=expand_delay_bar, EXPAND_PLAY_BAR=expand_play_bar, $
           EXPAND_RANGE_BAR=expand_range_bar

      multiple = 0
      saveable = 0
      if valid then $
           self.animation->GetProperty, MULTIPLE=multiple, SAVEABLE=saveable

      ;; Set menu state

      obar->SetItem, 'File.Export Animation', SENSITIVE=(n_frames gt 0)
      obar->SetItem, 'File.Export Frame', SENSITIVE=(n_frames gt 0)
      obar->SetItem, 'File.Print Frame', SENSITIVE=(n_frames gt 0)

      obar->SetItem, 'Tools.Set Cumulative', SENSITIVE=multiple

      obar->SetItem, 'Window.Expand/Collapse.Slider Bar', SENSITIVE=(1-slave)
      obar->SetItem, 'Window.Expand/Collapse.Play Bar', SENSITIVE=(1-slave)
      obar->SetItem, 'Window.Expand/Collapse.Delay Bar', SENSITIVE=(1-slave)
      obar->SetItem, 'Window.Expand/Collapse.Range Bar', SENSITIVE=(1-slave)

   endif

end

; MGH_DGplayer::WriteAnimationToMovieFile
;
pro MGH_DGplayer::WriteAnimationToMovieFile, File, $
     DISPLAY=display, RESOLUTION=resolution, RANGE=range, STRIDE=stride, TYPE=type

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(type) eq 0 then type = 'FLC'

   type = strupcase(type)

   if n_elements(display) eq 0 then display = 1B

   ;; Establish frames to be plotted

   self.animation->GetProperty, N_FRAMES=n_frames

   self.animator->GetPlayBack, RANGE=play_range, USE_RANGE=play_use_range

   case play_use_range of
      0: begin
         if n_elements(range) eq 0 then range = [0,n_frames-1]
         if n_elements(stride) eq 0 then stride = 1
      end
      1: begin
         if n_elements(range) eq 0 then range = play_range[0:1]
         if n_elements(stride) eq 0 then stride = play_range[2]
      end
   endcase

   n_written = 1 + (range[1]-range[0])/stride

   ;; Save the Direct Graphics state

   d_name = !d.name

   set_plot, self.display_name

   tvlct, r, g, b, /GET

   d_window = !d.window

   ;; Work through frames, rendering the commands to the pixmap, taking snapshots

   wset, self.pixmap

   for pos=range[0],range[1],stride do begin

      if self.erase then erase, COLOR=self.background

      self->SetProperty, COMMANDS=self.animation->AssembleFrame(pos)

      if display then self->Draw

      for i=0,self.commands->Count()-1 do begin
         command = self.commands->Get(POSITION=i)
         if obj_valid(command) then command->Execute
      endfor

      snapshot = tvrd(/TRUE)

      if pos eq range[0] then begin
         dim = size(snapshot, /DIMENSIONS)
         print, self, ': Writing ', strtrim(n_written,2), $
                ' frames of ', strtrim(dim[1],2), ' x ', $
                strtrim(dim[2],2), ' to ', type, ' file ', file
         omovie = obj_new( 'MGHgrMovieFile', FILE=File, FORMAT=type)
      endif

      omovie->Put, reverse(temporary(snapshot), 3)

   endfor

   ;; Restore the direct graphics state

   tvlct, r, g, b

   wset, d_window

   set_plot, d_name

   ;; Save movie and update plot

   print, self, ': Saving '+type+' file...'
   omovie->Save
   print, self, ': Finished saving '+type+' file'

   obj_destroy, omovie

   self->Update

end

; MGH_DGplayer::WriteAnimationToVideoFile
;
pro MGH_DGplayer::WriteAnimationToVideoFile, File, $
   CODEC=codec, DISPLAY=display, FORMAT=format, FPS=fps, $
   QUALITY=quality, RESOLUTION=resolution, RANGE=range, STRIDE=stride

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ mgh_class_exists('IDLffVideoWrite') then $
      message, 'IDLffVideoWrite class is not available'

   if n_elements(display) eq 0 then display = !true

   if n_elements(fps) eq 0 then fps = 15

   if n_elements(quality) eq 0 then quality = 0.15

   ;; Establish frames to be plotted

   self.animation->GetProperty, N_FRAMES=n_frames

   self.animator->GetPlayBack, RANGE=play_range, USE_RANGE=play_use_range

   if play_use_range then begin
      if n_elements(range) eq 0 then range = play_range[0:1]
      if n_elements(stride) eq 0 then stride = play_range[2]
   endif else begin
      if n_elements(range) eq 0 then range = [0,n_frames-1]
      if n_elements(stride) eq 0 then stride = 1
   endelse

   n_written = 1 + (range[1]-range[0])/stride

   ;; Save the Direct Graphics state

   d_name = !d.name

   set_plot, self.display_name

   tvlct, r, g, b, /GET

   d_window = !d.window

   ;; Work through frames, rendering the commands to the pixmap, taking snapshots

   wset, self.pixmap

   n_written = 1 + (range[1]-range[0])/stride

   for pos=range[0],range[1],stride do begin

      if self.erase then erase, COLOR=self.background

      self->SetProperty, COMMANDS=self.animation->AssembleFrame(pos)

      if display then self->Draw

      for i=0,self.commands->Count()-1 do begin
         command = self.commands->Get(POSITION=i)
         if obj_valid(command) then command->Execute
      endfor

      snapshot = tvrd(/TRUE)

      if pos eq range[0] then begin

         ;; Determine dimensions of image data. The snapshot has been
         ;; produced from a true-colour buffer, so we know it is
         ;; dimensioned [3,m,n]

         dim = (size(snapshot, /DIMENSIONS))[1:2]

         fmt ='(%"Writing %d frames of %d x %d to video file %s")'
         message, /INFORM, string(n_written, dim, file, FORMAT=fmt)

         ovid = obj_new('IDLffVideoWrite', FORMAT=format, file)

         bit_rate = quality*dim[0]*dim[1]*24*fps

         stream = ovid.AddVideoStream(dim[0], dim[1], fps, BIT_RATE=bit_rate, CODEC=codec)

      endif

      !null = oVid.Put(stream, snapshot)

   endfor

   obj_destroy, ovid

   ;; Restore the direct graphics state

   tvlct, r, g, b

   wset, d_window

   set_plot, d_name

   fmt ='(%"Finished saving video file %s")'
   message, /INFORM, string(file, FORMAT=fmt)

end

pro MGH_DGplayer__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_DGplayer, inherits MGH_DGwindow, $
                 animator: obj_new(), animation: obj_new(), $
                 cumulative: 0L}

end


