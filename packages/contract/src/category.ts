import { z } from "@hono/zod-openapi";
import { MemberColorCode } from "./member.ts";

export const CategoryName = z.string().trim().min(1).max(30);

export const CategoryDto = z
	.object({
		id: z.uuid(),
		name: CategoryName,
		color: MemberColorCode,
		archived: z.boolean(),
	})
	.openapi("CategoryDto");
export type CategoryDto = z.infer<typeof CategoryDto>;

export const CategoriesResponse = z
	.object({ categories: z.array(CategoryDto) })
	.openapi("CategoriesResponse");

export const CategoryResponse = z
	.object({ category: CategoryDto })
	.openapi("CategoryResponse");

export const CreateCategoryRequest = z
	.object({ name: CategoryName, color: MemberColorCode })
	.openapi("CreateCategoryRequest");
export type CreateCategoryRequest = z.infer<typeof CreateCategoryRequest>;

export const UpdateCategoryRequest = z
	.object({
		name: CategoryName.optional(),
		color: MemberColorCode.optional(),
	})
	.refine((request) => Object.keys(request).length > 0)
	.openapi("UpdateCategoryRequest");
export type UpdateCategoryRequest = z.infer<typeof UpdateCategoryRequest>;
