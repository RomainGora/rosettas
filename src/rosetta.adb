with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;

use Ada.Numerics;
use Ada.Numerics.Elementary_Functions;

package body Rosetta is

   --  Computes a single point on the hypotrochoid curve for a given angle Theta.
   --  Uses the standard parametric equation of a hypotrochoid.
   function Generate_Point (Curve : Hypotrochoid; Theta : Float) return Coordinate is
      R_Diff : constant Float := Curve.Outer_Radius - Curve.Inner_Radius;
      Ratio  : constant Float := R_Diff / Curve.Inner_Radius;
   begin
      return (
              X_Coord => R_Diff * Cos (Theta) + Curve.Pen_Offset * Cos (Ratio * Theta),
              Y_Coord => R_Diff * Sin (Theta) - Curve.Pen_Offset * Sin (Ratio * Theta)
             );
   end Generate_Point;

   --  Computes all the points of the hypotrochoid curve and recenters them.
   --  The result is an array of coordinates centered around the origin.
   function Compute_Points (Curve : Hypotrochoid) return Coordinate_Array is
      Points : Coordinate_Array (0 .. Curve.Steps);
      Max_X  : Float := Float'First;
      Min_X  : Float := Float'Last;
      Max_Y  : Float := Float'First;
      Min_Y  : Float := Float'Last;
      Offset : Coordinate;
   begin
      --  Computes raw points and updates the bounding box extents.
      for J in 0 .. Curve.Steps loop
         declare
            Theta : constant Float := 2.0 * Pi * Float (J) / Float (Curve.Steps) * 50.0;
            P     : constant Coordinate := Generate_Point (Curve, Theta);
         begin
            Points (J) := P;
            Max_X := Float'Max (Max_X, P.X_Coord);
            Min_X := Float'Min (Min_X, P.X_Coord);
            Max_Y := Float'Max (Max_Y, P.Y_Coord);
            Min_Y := Float'Min (Min_Y, P.Y_Coord);
         end;
      end loop;

      --  Computes the center offset based on the bounding box.
      Offset := (
                 X_Coord => (Max_X + Min_X) / 2.0,
                 Y_Coord => (Max_Y + Min_Y) / 2.0
                );

      --  Recenters all points by subtracting the center offset.
      for J in Points'Range loop
         Points (J).X_Coord := @ - Offset.X_Coord;
         Points (J).Y_Coord := @ - Offset.Y_Coord;
      end loop;

      return Points;
   end Compute_Points;

   --  Redefines the 'Image attribute for Coordinate.
   procedure Put_Image_Coordinate
     (Output : in out Ada.Strings.Text_Buffers.Root_Buffer_Type'Class;
      Value  : Coordinate)
   is
      X_Text : constant String := Float'Image (Value.X_Coord);
      Y_Text : constant String := Float'Image (Value.Y_Coord);
   begin
      Output.Put (X_Text & "," & Y_Text);
   end Put_Image_Coordinate;

end Rosetta;
