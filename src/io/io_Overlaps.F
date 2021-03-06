!
!        Copyright (C) 2000-2015 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): AM
! 
! This file is distributed under the terms of the GNU 
! General Public License. You can redistribute it and/or 
! modify it under the terms of the GNU General Public 
! License as published by the Free Software Foundation; 
! either version 2, or (at your option) any later version.
!
! This program is distributed in the hope that it will 
! be useful, but WITHOUT ANY WARRANTY; without even the 
! implied warranty of MERCHANTABILITY or FITNESS FOR A 
! PARTICULAR PURPOSE.  See the GNU General Public License 
! for more details.
!
! You should have received a copy of the GNU General Public 
! License along with this program; if not, write to the Free 
! Software Foundation, Inc., 59 Temple Place - Suite 330,Boston, 
! MA 02111-1307, USA or visit http://www.gnu.org/copyleft/gpl.txt.
!
integer function io_Overlaps(X,ID)
 !
 use pars,          ONLY:SP,schlen
 use X_m,           ONLY:X_t,X_alloc
 use electrons,     ONLY:levels
 use R_lattice,     ONLY:nXkbz
 use matrix_operate,ONLY:mat_c2r,mat_r2c
 use IO_m,          ONLY:io_connect,io_disconnect,io_sec,frag_DIP,&
&                        io_bulk,read_is_on,write_is_on,io_header,io_extension,&
&                        RD_CL_IF_END,RD_CL,io_action,&
&                        IO_NOT_ALLOWED,io_DIP,io_fragment
 use X_m,           ONLY:DIP_S
#if defined _TIMING
 use timing_m,      ONLY:timing
#endif
 !
 implicit none
 type(X_t)   ::X
 integer     ::ID
 !
 ! Work Space
 !
 integer :: ik,ik_mem,i_fragment,ixyz,i_sp_pol,shift(2)
 integer, external    :: variables_DIPOLES
 character(schlen)    :: VAR_name
 real(SP),allocatable :: disk_data(:,:,:)
 !
 if (.not.io_DIP) then
   io_Overlaps=IO_NOT_ALLOWED
   call io_disconnect(ID,FORCE=.TRUE.)
   return
 endif
 !
#if defined _TIMING
 call timing('io_Overlaps',OPR='start')
#endif
 !
 io_extension(ID)='Overlap'
 !
 io_Overlaps=io_connect(desc=trim(io_extension(ID)),type=2,ID=ID)
 if (io_Overlaps/=0) goto 1
 !
 if (any((/io_sec(ID,:)==1/))) then
   !
   io_Overlaps=io_header(ID,R_LATT=.true.,WF=.true.,IMPOSE_SN=.true.,T_EL=.true.,FRAG=frag_DIP)
   if (io_Overlaps/=0) goto 1
   !
   io_Overlaps=variables_DIPOLES(X,ID)
   if (io_Overlaps/=0) goto 1
   !
 endif
 !
 i_fragment=maxval(io_sec(ID,:))-1
 if(i_fragment<=nXkbz) then
   i_sp_pol=1
   ik=i_fragment
 else
   i_sp_pol=2
   ik=i_fragment-nXkbz
 endif
 !
 if (ik==0) goto 1
 !
 ik_mem=ik 
 !
 allocate(disk_data(X%ib(2),X%ib(2),2))
 !
 if (read_is_on(ID)) then
   call X_alloc('DIP_S',(/X%ib(2),X%ib(2),6,nXkbz/))
 endif
 !
 ! Fragmentation
 !
 call io_fragment(ID,i_fragment=i_fragment)
 !
 ! Manage RD_CL_IF_END
 !
 if (io_action(ID)==RD_CL_IF_END.and.ik==nXkbz) io_action(ID)=RD_CL
 !
 do ixyz=1,6
   !
   ! S
   !
   if (write_is_on(ID)) call mat_c2r(DIP_S(:,:,ixyz,ik_mem,i_sp_pol),disk_data)
   write (VAR_name,'(3(a,i4.4))') 'DIP_S_k_',ik,'_xyz_',ixyz,'_spin_',i_sp_pol
   call io_bulk(ID,VAR=trim(VAR_name),VAR_SZ=shape(disk_data))
   call io_bulk(ID,R3=disk_data)
   if (read_is_on(ID)) call mat_r2c(disk_data,DIP_S(:,:,ixyz,ik_mem,i_sp_pol))
   !
 enddo
 !
 deallocate(disk_data)
 !
1 call io_disconnect(ID=ID)
 !
#if defined _TIMING
 if (io_DIP) call timing('io_Overlaps',OPR='stop')
#endif
 !
end function
