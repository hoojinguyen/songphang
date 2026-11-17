"use client";
import { FeaturesResponse } from "@songphang/contract";
import { useQuery } from "@tanstack/react-query";
import type { z } from "zod";
import { type ApiError, apiFetch } from "./api";

export function useFeatures() {
	return useQuery<z.infer<typeof FeaturesResponse>, ApiError>({
		queryKey: ["features"],
		queryFn: () => apiFetch("/features", FeaturesResponse),
		staleTime: Number.POSITIVE_INFINITY,
		gcTime: Number.POSITIVE_INFINITY,
	});
}
