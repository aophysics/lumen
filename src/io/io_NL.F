!
!        Copyright (C) 2000-2015 the YAMBO team
!              http://www.yambo-code.org
!
! Authors (see AUTHORS file for details): MG, CA
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
integer function io_NL(ID)
 !
 use pars,          ONLY:SP,schlen,lchlen
 use units,         ONLY:HA2EV, AU2KWCMm2, AUT2FS
 use nl_optics,     ONLY:E_tot_t,E_ext_t,E_ks_t,NL_P_t,NL_damping,l_use_DIPOLES, &
&                        NL_correlation,NL_er,NL_correlation,n_runs,Integrator_name, &
&                        NL_steps,NL_step
 use matrix_operate,ONLY:mat_r2c,mat_c2r
 use fields,        ONLY:Efield
 use memory_m,      ONLY:mem_est
 use electrons,     ONLY:levels
 use IO_m,          ONLY:io_connect,io_disconnect,io_sec,&
&                        io_bulk,read_is_on,write_is_on,io_header,io_extension,&
&                        RD_CL_IF_END,RD_CL,io_action,io_fragment,io_elemental,io_status
 !
#if defined _TIMING
 use timing_m,      ONLY:timing
#endif
 !
 implicit none
 integer,      intent(in) :: ID
 !
 integer, external    :: variables_NL
 !
 ! Work Space
 !
 integer              :: i_fragment,io_err
 character(lchlen)    :: local_description(100)
 character(schlen)    :: VAR_name
 integer, parameter   :: i_Prb=1
 !
#if defined _TIMING
 call timing('io_NL',OPR='start')
#endif
 !
 io_extension(ID)='Nonlinear'
 !
 io_NL=io_connect(desc=trim(io_extension(ID)),type=2,ID=ID)
 if (io_NL/=0) goto 1
 !
 if (any((/io_sec(ID,:)==1/))) then
   !
   io_NL=io_header(ID,R_LATT=.true.,WF=.true.,IMPOSE_SN=.true.,GAUGE=.true.,CUTOFF=.true.)
   if (io_NL/=0) goto 1
   !
   io_NL=variables_NL(ID,local_description)
   !
   if (io_NL/=0) goto 1
   !
 endif
 !
 i_fragment=maxval(io_sec(ID,:))-1
 !
 if (i_fragment==0) goto 1
 !
 if(read_is_on(ID)) then
   !  
   if(.not.allocated(NL_P_t)) then
     !
     allocate(NL_P_t(NL_steps,3))
     call mem_est("NL_P_t",(/size(NL_P_t)/))
     !
     allocate(E_tot_t(NL_steps,3),E_ext_t(NL_steps,3),E_ks_t(NL_steps,3))
     call mem_est("E_tot_t E_ext_t",(/size(E_tot_t),size(E_ext_t),size(E_ks_t)/))
     !
   endif
   !
 endif
 !
 ! Fragmentation
 !
 call io_fragment(ID,i_fragment=i_fragment,ierr=io_err)
 if(io_err/=0) then
   io_NL=io_err
   goto 1
 endif
 !
 ! Manage RD_CL_IF_END
 !
 if (io_action(ID)==RD_CL_IF_END.and.i_fragment==n_runs) io_action(ID)=RD_CL
 !
 ! Efield 
 !
 call io_elemental(ID,VAR="FIELD_NAME",CH0="",VAR_SZ=1,MENU=0)
 call io_elemental(ID,CH0=Efield(i_Prb)%ef_name,VAR=' [FIELDs] Type           :',CHECK=.true.,OP=(/"=="/))
 call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
 !
 call io_elemental(ID,VAR="EXTERNAL_FIELD",VAR_SZ=7,MENU=0)
 call io_elemental(ID,VAR="[FIELDs] Versor                :",R1=Efield(i_Prb)%versor,WARN=.true.,OP=(/"==","==","=="/))
 call io_elemental(ID,VAR="[FIELDs] Intensity     [kWCMm2]:",R0=Efield(i_Prb)%intensity,CHECK=.true.,OP=(/"=="/),UNIT=AU2KWCMm2)
 call io_elemental(ID,VAR="[FIELDs] Damping           [fs]:",R0=Efield(i_Prb)%damping,CHECK=.true.,OP=(/"=="/))
 call io_elemental(ID,VAR="[FIELDs] Frequency         [eV]:",R0=Efield(i_Prb)%frequency,CHECK=.true.,OP=(/"=="/),UNIT=HA2EV)
 call io_elemental(ID,VAR='[FIELDs] Initial time      [fs]:',R0=Efield(i_Prb)%t_initial,CHECK=.true.,OP=(/"=="/),UNIT=AUT2FS)
 call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
 !
 call io_elemental(ID,VAR="FIELD_POL",CH0="",VAR_SZ=1,MENU=0)
 call io_elemental(ID,CH0=Efield(i_Prb)%ef_pol,VAR="[FIELDs] Polarization :",CHECK=.true.,OP=(/"=="/))
 call io_elemental(ID,VAR="",VAR_SZ=0,MENU=0)
 !
 ! Polarization
 !  
 write (VAR_name,'(a,i4.4)') 'NL_P_freq_',i_fragment
 call io_bulk(ID,VAR=trim(VAR_name),VAR_SZ=shape(NL_P_t))
 call io_bulk(ID,R2=NL_P_t)
 !
 ! E_ext
 ! 
 write (VAR_name,'(a,i4.4)') 'E_ext_freq_',i_fragment
 call io_bulk(ID,VAR=trim(VAR_name),VAR_SZ=shape(E_ext_t))
 call io_bulk(ID,R2=E_ext_t)
 !
 ! E_tot
 ! 
 write (VAR_name,'(a,i4.4)') 'E_tot_freq_',i_fragment
 call io_bulk(ID,VAR=trim(VAR_name),VAR_SZ=shape(E_tot_t))
 call io_bulk(ID,R2=E_tot_t)
 !
 ! E_ks
 ! 
 write (VAR_name,'(a,i4.4)') 'E_ks_freq_',i_fragment
 call io_bulk(ID,VAR=trim(VAR_name),VAR_SZ=shape(E_ks_t))
 call io_bulk(ID,R2=E_ks_t)
 !
1 call io_disconnect(ID=ID)
 !
#if defined _TIMING
 call timing('io_NL',OPR='stop')
#endif
 !
end function
